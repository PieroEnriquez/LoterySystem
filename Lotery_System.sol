//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;
import "./ERC20.sol";

contract Loteria{
    //Instancia del contrato token
    ERC20Basic private token;

    //Evento de tokens comprados
    event compraTokens(uint, address);

    //Direcciones iniciales
    address public owner;
    address public contrato;

    constructor(){
        token = new ERC20Basic(10000);
        owner = payable(msg.sender);
        contrato = address(this);
    }

    // ------------------------------- TOKEN -------------------------------

    //Funcion para establecer el precio de un token
    function precioTokens(uint _numTokens) internal pure returns(uint){
        //Conversion de tokens a Ethers: 1 TEST = 1 Ether
        return _numTokens*(1 ether);
    }

    //Modificador para que solo el owner puede ejecutar una funcion
    modifier soloOwner(address _owner){
        require(_owner == owner, "No tienes permiso para ejecutar esta funcion");
        _;
    }

    //Generar mas tokens para la loteria
    function generarTokens(uint _numTokens) public soloOwner(msg.sender){
        token.increaseTotalSupply(_numTokens);
    }

    //Funcion para comprar tokens
    function comprarTokens(uint _numTokens) public payable{
        //Calcular el coste de los tokens
        uint coste = precioTokens(_numTokens);
        //Se requiere que se tenga el dinero para pagar los tokens
        require(msg.value >= coste, "No cuenta con el balance necesario");
        //Diferencia de tokens
        uint returnValue = msg.value - coste;
        //Transferencia de la diferencia
        payable(msg.sender).transfer(returnValue);
        //Obtener el balance de tokens del contrato
        uint Balance = tokensDisponibles();
        //Filtro para saber si los tokens que se quieren comprar, existen
        require(_numTokens >= Balance, "No se dispone de la cantidad de tokens que desea comprar");
        //Transferencia de tokens
        token.transfer(msg.sender, _numTokens);
        //Evento de compra de tokens
        emit compraTokens(_numTokens, msg.sender);
    }

    //Balance de tokens en el contrato
    function tokensDisponibles() public view returns(uint){
        return token.balanceOf(contrato);
    }

    //Obtener el balance de tokens que se acumulan en el bote
    function bote() public view returns(uint){
        return token.balanceOf(owner);
    }

    //Funcion para ver la cantidad de tokens que tiene una persona
    function misTokens() public view returns(uint){
        return token.balanceOf(msg.sender);
    }

    // ------------------------------- LOTERIA -------------------------------

    //Precio del boleto
    uint public precioBoleto = 5;

    //Relacion entre la persona que compra los boletos y su numero de boleto
    mapping(address => uint[]) idPersonaBoletos;

    //Relacion para identificar al ganador
    mapping(uint => address) ADNboleto;

    //Numero aleatorio
    uint randNonce = 0;

    //Boletos generados
    uint[] boletosComprados;

    //Evento de boletos comprados
    event BoletoComprado(uint, address);
    //Evento de boleto ganador
    event BoletoGanador(uint);
    //Evento de devolucion de tokens
    event DevolverTokens(uint, address);

    //Funcion para comprar boletos
    function compraBoletos(uint _numBoletos) public{
        //Precio de los boletos
        uint precioBoletos = _numBoletos*precioBoleto;
        //Filtro de los tokens a pagar
        require(precioBoletos <= misTokens(), "No cuenta con la cantidad de tokens requerida");
        /*
        El cliente paga el boleto en tokens, por lo que se creo una funcion en el contrato del token con el nombre transferClient, ya que,
        en caso de usar transfer o transferFrom, las direcciones eran equivocadas por recibir la direccion del mismo contrato y no quien lo ejecuta
        */
        token.transferClient(msg.sender, owner, precioBoletos);
        /*
        Creacion de un numero aleatorio para el numero de boletos, tomando el tiempo actual, el msg.sender y el nonce
        (un numero que solo se usa una vez, para no ejecutar la misma funcion dos veces y, así, no se repita el numero)
        Luego, se usa keccak256 para convertir esto en un hash aleatorio que, luego, se vuelve un uint que se divide entre 10000
        para tomar los ultimos 4 digitos, dando un valor aleatorio entre 0 - 9999
        */
        for(uint i = 0; i < _numBoletos; i++){
            uint random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce)))%10000;
            randNonce++;
            //Se almacenan los datos de los boletos
            idPersonaBoletos[msg.sender].push(random);
            //Numero de boletos comprados
            boletosComprados.push(random);
            //Asignacion del adn del boleto para tener un ganador
            ADNboleto[random] = msg.sender;
            //Emision del evento
            emit BoletoComprado(_numBoletos, msg.sender);
        }
    }

    //Funcion para ver los boletos comprados
    function misBoletos() public view returns(uint[]memory){
        return idPersonaBoletos[msg.sender];
    }

    //Funcion para generar un ganador y darle los tokens
    function generarGanador() public payable soloOwner(msg.sender){
        //Cantidad de boletos comprados debe ser mayor a 0
        require(boletosComprados.length > 0);
        //Declaracion de la longitud del array
        uint longitud = boletosComprados.length;
        //Aleatoriamente se elige un numero entre el 0 y la longitud
        uint posicionArray = uint(uint(keccak256(abi.encodePacked(block.timestamp)))%longitud);
        //Seleccion del numero aleatorio mediante la posicion del array aleatoria
        uint eleccion = boletosComprados[posicionArray];
        //Emision del evento del ganador
        emit BoletoGanador(eleccion);
        //Se recupera la address del ganador
        address direccionGanador = ADNboleto[eleccion];
        //Enviarle los tokens del premio al ganador
        token.transferClient(msg.sender, direccionGanador, bote());
    }

    //Funcion que permita cambiar los tokens por ethers
    function devolverTokens(uint _numTokens) public payable{
        //El numero de tokens debe ser mayor a 0
        require(_numTokens > 0, "Debes devolver una cantidad positiva de tokens");
        //El usuario debe tener la cantidad de tokens que desea devolver
        require(_numTokens <= misTokens(), "No tienes los tokens que deseas devolver");
        //El cliente devuelve los tokens
        token.transferClient(msg.sender, contrato, _numTokens);
        payable(msg.sender).transfer(precioTokens(_numTokens));
        //Se emite el evento de tokens devueltos
        emit DevolverTokens(_numTokens, msg.sender);
    }

}