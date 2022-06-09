//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "./ERC20.sol";

contract Lotery{
    //Token contract instance
    ERC20Basic private token;

    //Event for buyed tokens
    event buyedTokens(uint, address);

    //Initial addresses
    address public owner;
    address public lotery_contract;

    constructor(){
        //Setting the amount of tokens to 10000
        token = new ERC20Basic(10000);
        owner = payable(msg.sender);
        lotery_contract = address(this);
    }

    // ------------------------------- TOKEN -------------------------------

    //Function to stablish the price of a token
    function tokenPrice(uint _numTokens) internal pure returns(uint){
        //Converting tokens to Ethers: 1 TEST = 1 Ether
        return _numTokens*(1 ether);
    }

    //Modifier to only let the owner of the contract run a function
    modifier onlyOwner(address _owner){
        require(_owner == owner, "You have no permission to run this function");
        _;
    }

    //Generating more tokens for the lotery
    function generateTokens(uint _numTokens) public onlyOwner(msg.sender){
        token.increaseTotalSupply(_numTokens);
    }

    //Buying tokens
    function buyTokens(uint _numTokens) public payable{
        //Calculating tokens price
        uint cost = tokenPrice(_numTokens);
        //It requires the user having the amount of money to acquire the tokens
        require(msg.value >= cost, "Not enough balance to get this amount");
        //Calculating the diference between the amount the user has and the the amount of tokens the user wants to get
        uint returnValue = msg.value - cost;
        //Transfering the diference
        payable(msg.sender).transfer(returnValue);
        //Getting the token balance of the contract
        uint Balance = tokensDisponibles();
        //Filter in case there's not enough of tokens available in the contract
        require(_numTokens >= Balance, "There's not enough tokens available");
        //Transfering the tokens
        token.transfer(msg.sender, _numTokens);
        //Emiting the event for token buying
        emit buyedTokens(_numTokens, msg.sender);
    }

    //Balance de tokens en el contrato
    function tokensDisponibles() public view returns(uint){
        return token.balanceOf(lotery_contract);
    }

    //Obtener el balance de tokens que se acumulan en el bote
    function bote() public view returns(uint){
        return token.balanceOf(owner);
    }

    //Funcion para ver la cantidad de tokens que tiene una persona
    function misTokens() public view returns(uint){
        return token.balanceOf(msg.sender);
    }

    // ------------------------------- LOTERY -------------------------------

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
    function generarGanador() public payable onlyOwner(msg.sender){
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
        token.transferClient(msg.sender, lotery_contract, _numTokens);
        payable(msg.sender).transfer(tokenPrice(_numTokens));
        //Se emite el evento de tokens devueltos
        emit DevolverTokens(_numTokens, msg.sender);
    }

}