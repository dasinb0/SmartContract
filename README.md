<b>Auction Smart Contract</b>
Este contrato de subasta en Solidity está diseñado para permitir subastas en la red Sepolia de Scroll. Implementa una serie de características avanzadas para mejorar la experiencia de los ofertantes y el control de la subasta. A continuación, se describen las funcionalidades principales.

<b>Descripción del Contrato</b>
Este contrato permite a los usuarios realizar ofertas en una subasta. Incluye una extensión automática del plazo de la subasta si se recibe una oferta en los últimos 10 minutos, así como reembolsos parciales a los ofertantes no ganadores con una comisión del 2% para cubrir el costo del gas.

<b>Características Clave</b>
Ofertas Incrementales: Las nuevas ofertas deben ser al menos un 5% superiores a la oferta más alta actual.
Extensión Automática: La subasta se extiende 10 minutos si se realiza una oferta válida en los últimos 10 minutos de la subasta.
Reembolso Parcial: Los ofertantes no ganadores pueden retirar su depósito menos una comisión del 2%.
Eventos de Seguimiento: Emite eventos para nuevas ofertas, finalización de la subasta y reembolsos parciales.

<b>Funciones Principales</b>
Constructor: Inicializa el contrato y establece la duración de la subasta.
bid: Permite a los usuarios realizar una oferta en la subasta.
withdrawExcess: Permite a los ofertantes retirar parte de su depósito, manteniendo el saldo mínimo necesario.
endAuction: Finaliza la subasta y permite el retiro de los depósitos, distribuyendo el monto final al ganador y los reembolsos a los no ganadores.
getWinner: Devuelve el ganador actual y la oferta más alta.
getAllBids: Muestra todas las ofertas realizadas, junto con los detalles de los ofertantes.
getRemainingTime: Proporciona el tiempo restante de la subasta.
getContractBalance: Devuelve el balance actual del contrato.

<b>Eventos</b>
NewBid: Se emite cuando se recibe una nueva oferta.
AuctionEnded: Indica el final de la subasta, incluyendo los detalles del ganador y la oferta ganadora.
PartialRefund: Se emite cuando se realiza un reembolso parcial.

<b>Modificadores</b>
onlyOwner: Restringe el acceso a ciertas funciones solo al propietario del contrato.
auctionActive: Asegura que la subasta esté activa antes de ejecutar una función.
auctionEnded: Verifica que la subasta haya terminado.

<b>Errores Personalizados</b>
AuctionNotActive: Se lanza si la subasta no está activa.
BidTooLow: Se lanza si la oferta no cumple el incremento mínimo.
TransferFailed: Se lanza si ocurre un fallo en la transferencia de fondos.
AuctionNotEnded: Se lanza si la subasta aún no ha finalizado.
NotAuthorized: Se lanza si un usuario intenta realizar una operación sin autorización.

<b>Uso del Contrato</b>
Para desplegar y usar este contrato, los usuarios deben:

Desplegar el contrato con una duración específica para la subasta.
Realizar ofertas con la función bid asegurándose de que cumplen el incremento mínimo.
Retirar su oferta excedente (si no son el mayor postor) usando withdrawExcess.
Consultar el estado de la subasta, el ganador actual y el balance del contrato.

<b>Requerimientos</b>
Solidity ^0.8.0
Desplegado en la red Sepolia de Scroll
