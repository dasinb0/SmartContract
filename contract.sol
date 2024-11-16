/**
 *Submitted for verification at sepolia.scrollscan.com on 2024-11-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Contrato de Subasta
 * @dev Implementa una subasta con extensión automática y reembolsos parciales
 */
contract Auction {
    address payable public owner;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public highestBid;
    address payable public highestBidder;
    bool public ended;
    
    // Mapeo de direcciones a sus ofertas
    mapping(address => uint256) public bids;
    // Array para almacenar todas las direcciones que han ofertado
    address payable[] public bidders;
    
    // Constantes
    uint256 private constant MIN_BID_INCREASE = 5; // 5% de incremento mínimo
    uint256 private constant EXTENSION_TIME = 10 minutes;
    uint256 private constant COMMISSION_RATE = 2; // 2% de comisión
    
    // Eventos
    event NewBid(address indexed bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);
    event PartialRefund(address indexed bidder, uint256 amount);
    
    // Errores personalizados
    error AuctionNotActive();
    error BidTooLow();
    error TransferFailed();
    error AuctionNotEnded();
    error NotAuthorized();
    
    // Modificadores
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotAuthorized();
        _;
    }
    
    modifier auctionActive() {
        if (ended || block.timestamp >= endTime) revert AuctionNotActive();
        _;
    }
    
    modifier auctionEnded() {
        if (!ended && block.timestamp < endTime) revert AuctionNotEnded();
        _;
    }
    
    /**
     * @dev Constructor que inicializa la subasta
     * @param _duration Duración de la subasta en segundos
     */
    constructor(uint256 _duration) {
        require(_duration > 0, "La duracion debe ser mayor a 0");
        owner = payable(msg.sender);
        startTime = block.timestamp;
        endTime = startTime + _duration;
        ended = false;
    }
    
    /**
     * @dev Recibe ETH
     */
    receive() external payable {}
    
    /**
     * @dev Fallback function
     */
    fallback() external payable {}
    
    /**
     * @dev Permite a los participantes realizar ofertas
     */
  function bid() external payable auctionActive {
    require(msg.value > 0, "Debe enviar ETH para ofertar");
    require(msg.sender != owner, "El owner no puede ofertar");

    // Si el tiempo ya expiró y la subasta sigue activa, finalízala
    if (block.timestamp > endTime) {
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
        revert AuctionNotActive(); // Se finaliza y se evita la oferta
    }

    // Verificar que la oferta sea mayor que la actual más el 5%
    uint256 minBidRequired = highestBid + (highestBid * MIN_BID_INCREASE / 100);
    if (msg.value <= minBidRequired) revert BidTooLow();
        
        // Si el ofertante ya tiene una oferta anterior, actualizar su oferta total
        uint256 totalBid = bids[msg.sender] + msg.value;
        
        // Actualizar el registro de ofertas
        if (bids[msg.sender] == 0) {
            bidders.push(payable(msg.sender));
        }
        bids[msg.sender] = totalBid;
        
        // Actualizar la mejor oferta
        highestBid = totalBid;
        highestBidder = payable(msg.sender);
        
        // Extender el tiempo si estamos cerca del final
        if (block.timestamp >= endTime - EXTENSION_TIME) {
            endTime = block.timestamp + EXTENSION_TIME;
        }
        
        emit NewBid(msg.sender, totalBid);
    }
    
    /**
     * @dev Permite a los participantes retirar el exceso de su depósito
     * @param amount Cantidad a retirar
     */
    function withdrawExcess(uint256 amount) external auctionActive {
        uint256 currentBid = bids[msg.sender];
        require(currentBid > 0, "No tiene ofertas activas");
        require(amount <= currentBid, "Cantidad mayor al deposito");
        
        uint256 minimumRequired = highestBid;
        if (msg.sender == highestBidder) {
            minimumRequired = (highestBid * (100 + MIN_BID_INCREASE)) / 100;
        }
        
        require(currentBid - amount >= minimumRequired, "Debe mantener suficiente deposito");
        bids[msg.sender] -= amount;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();
        
        emit PartialRefund(msg.sender, amount);
    }
    
    /**
     * @dev Finaliza la subasta y permite retirar los depósitos
     */
    function endAuction() external auctionEnded {
        require(!ended, "La subasta ya ha finalizado");
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
        
        // Procesar reembolsos para los no ganadores
        for (uint i = 0; i < bidders.length; i++) {
            address payable bidder = bidders[i];
            if (bidder != highestBidder && bids[bidder] > 0) {
                uint256 refundAmount = bids[bidder];
                uint256 commission = (refundAmount * COMMISSION_RATE) / 100;
                uint256 netRefund = refundAmount - commission;
                bids[bidder] = 0;
                
                (bool success, ) = bidder.call{value: netRefund}("");
                if (!success) revert TransferFailed();
            }
        }
        
        // Transferir la comisión al owner
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = owner.call{value: balance}("");
            if (!success) revert TransferFailed();
        }
    }
    
    /**
     * @dev Obtiene el ganador actual de la subasta
     */
    function getWinner() external view returns (address winner, uint256 winningBid) {
        return (highestBidder, highestBid);
    }
    
  /**
     * @dev Obtiene todas las ofertas realizadas
     */
    function getAllBids() external view returns (address[] memory _bidders, uint256[] memory _amounts) {
        _bidders = new address[](bidders.length);
        _amounts = new uint256[](bidders.length);
        
        for (uint i = 0; i < bidders.length; i++) {
            _bidders[i] = address(bidders[i]);  // Convertimos address payable a address
            _amounts[i] = bids[bidders[i]];
        }
        return (_bidders, _amounts);
    }
    
    /**
     * @dev Obtiene el tiempo restante de la subasta
     */
    function getRemainingTime() external view returns (uint256) {
        if (ended || block.timestamp >= endTime) return 0;
        return endTime - block.timestamp;
    }
    
    /**
     * @dev Obtiene el balance actual del contrato
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
