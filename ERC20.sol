//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "./SafeMath.sol";


//Interface del token
interface IERC20{
    //Devuelve la cantidad de tokens en existencia
    function totalSupply() external view returns(uint256);

    //Devuelve la cantidad de tokens de una direccion especifica
    function balanceOf(address account) external view returns(uint256);

    //Devuelve el numero de tokens que el spender podra gastar en nombre del propietario(owner)
    function allowance(address owner, address spender) external view returns(uint256);

    //Devuelve un booleano resultado de la operacion indicada
    function transfer(address recipient, uint256 amount) external returns(bool);

    //Devuelve un booleano con el resultado de la operacion de gasto
    function approve(address spender, uint256 amount) external returns(bool);

    //Devuelve un booleano con el resultado de la operacion de paso de una cantidad de tokens usando el metodo allowance()
    function transferFrom(address sender, address recipient, uint256 tokens) external returns(bool);

    //Transferencia de tokens a otro address
    function transferClient(address _client, address recipient, uint256 numTokens) external returns(bool);

    //Evento que se debe emitir cuando una cantidad de tokens pase de un destino a otro
    event Transfer(address indexed from, address indexed to, uint256 value);

    //Evento que se debe emitir cuando se establece una asignacion con el metodo allowance
    event Approval(address indexed owner, address indexed expender, uint256 value);

}

contract ERC20Basic is IERC20{

    string public constant name = "Lotery";
    string public constant symbol = "LUCK";
    uint8 public constant decimals = 2;

    using SafeMath for uint256;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    uint256 totalSupply_;

    constructor(uint256 initialSupply){
        totalSupply_ = initialSupply;
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public override view returns(uint256){
        return totalSupply_;
    }

    function increaseTotalSupply(uint newTokensAmount) public {
        totalSupply_ += newTokensAmount;
        balances[msg.sender] += newTokensAmount;
    }

    function balanceOf(address tokenOwner) public override view returns(uint256){
        return balances[tokenOwner];
    }

    function allowance(address owner, address delegate) public override view returns(uint256){
        return allowed[owner][delegate];
    }

    function transfer(address recipient, uint256 numTokens) public override returns(bool){
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[recipient] = balances[recipient].add(numTokens);
        emit Transfer(msg.sender, recipient, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) external override returns(bool){
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) external override returns(bool){
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    function transferClient(address _client, address recipient, uint256 numTokens) public override returns(bool){
        require(numTokens <= balances[_client]);
        balances[_client] = balances[_client].sub(numTokens);
        balances[recipient] = balances[recipient].add(numTokens);
        emit Transfer(_client, recipient, numTokens);
        return true;
    }
}