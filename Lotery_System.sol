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
        uint Balance = availableTokens();
        //Filter in case there's not enough of tokens available in the contract
        require(_numTokens >= Balance, "There's not enough tokens available");
        //Transfering the tokens
        token.transfer(msg.sender, _numTokens);
        //Emiting the event for buying tokens
        emit buyedTokens(_numTokens, msg.sender);
    }

    //Token bakance on the contract
    function availableTokens() public view returns(uint){
        return token.balanceOf(lotery_contract);
    }

    //Amount of tokens accumulated in the boat
    function boat() public view returns(uint){
        return token.balanceOf(owner);
    }

    //Funcion para ver la cantidad de tokens que tiene una persona
    function myTokens() public view returns(uint){
        return token.balanceOf(msg.sender);
    }

    // ------------------------------- LOTERY -------------------------------

    //Amount of tokens necessary to buy a lottery ticket
    uint public ticketPrice = 5;

    //Relating people's address with their ticket number
    mapping(address => uint[]) idPeopleTickets;

    //Mapping to identify the winner of the lotery
    mapping(uint => address) DNAticket;

    //Random number: This will be used to create a unique ticket number
    uint randNonce = 0;

    //Generated tickets
    uint[] generatedTickets;

    //Event for buyed tickets
    event BuyedTicket(uint, address);
    //Event for the winner ticket
    event WinnerTicket(uint);
    //Event for returning tickets
    event ReturnTokens(uint, address);

    //Function to buy tickets
    function buyTickets(uint _numTickets) public{
        //Price to buy tickets
        uint priceTickets = _numTickets*ticketPrice;
        //Filter for buyed tokens
        require(priceTickets <= myTokens(), "You don't have the required amount of tokens");
        /*
        Client pays the ticket with tokens, so I had to create a function in the token contract
        named "transferClient", because, in case I use "transfer" or "transferFrom", addresses'
        recived are from the contract and not the person who executes the function
        */
        token.transferClient(msg.sender, owner, priceTickets);
        /*
        Creation of a random number for the ticket number, taking exact time, msg.sender and the
        nonce (number used only once so the function can't send the same number twice). Then,
        I used keccak256 to convert this data to a random hash that transform into an uint which
        divides by 10000 to take the last 4 digits, taking a value between 0 and 9999
        */
        for(uint i = 0; i < _numTickets; i++){
            uint random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce)))%10000;
            randNonce++;
            //Saving ticket data
            idPeopleTickets[msg.sender].push(random);
            //Numof buyed tickets
            generatedTickets.push(random);
            //Asigning the ticket dna to get later a winner
            DNAticket[random] = msg.sender;
            //Emiting the event
            emit BuyedTicket(_numTickets, msg.sender);
        }
    }

    //Function to view my buyed tickets
    function myTickets() public view returns(uint[]memory){
        return idPeopleTickets[msg.sender];
    }

    //Function to get a winner and give the tokens
    function generateWinner() public payable onlyOwner(msg.sender){
        //Amount of buyed tickets must be bigger than 0
        require(generatedTickets.length > 0);
        //Declaration of array's length
        uint length = generatedTickets.length;
        //Randmoly picking a number between 0 and the array's length
        uint positionArray = uint(uint(keccak256(abi.encodePacked(block.timestamp)))%length);
        //Selecting the random ticket number throught the random array's position
        uint electing = generatedTickets[positionArray];
        //Emiting the winner event
        emit WinnerTicket(electing);
        //Getting the winner's address
        address winnerAddress = DNAticket[electing];
        //Sending tokens to the winner
        token.transferClient(msg.sender, winnerAddress, boat());
    }

    //Funcion que permita cambiar los tokens por ethers
    function devolverTokens(uint _numTokens) public payable{
        //El numero de tokens debe ser mayor a 0
        require(_numTokens > 0, "Debes devolver una cantidad positiva de tokens");
        //El usuario debe tener la cantidad de tokens que desea devolver
        require(_numTokens <= myTokens(), "No tienes los tokens que deseas devolver");
        //El cliente devuelve los tokens
        token.transferClient(msg.sender, lotery_contract, _numTokens);
        payable(msg.sender).transfer(tokenPrice(_numTokens));
        //Se emite el evento de tokens devueltos
        emit ReturnTokens(_numTokens, msg.sender);
    }

}