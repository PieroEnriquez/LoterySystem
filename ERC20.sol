//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "./SafeMath.sol";


//Token interface
interface IERC20{
    //Total amount of token supply
    function totalSupply() external view returns(uint256);

    //Gives back the amount of tokens from an specific address
    function balanceOf(address account) external view returns(uint256);

    //Gives back the amount of tokens the spender can spend from the owner
    function allowance(address owner, address spender) external view returns(uint256);

    //Gives back a boolean resulting from the indicated operation
    function transfer(address recipient, uint256 amount) external returns(bool);

    //Gives a boolean resulting from an spending operation
    function approve(address spender, uint256 amount) external returns(bool);

    //Gives back a boolean resulting from an operation transfering tokens using allowance() method
    function transferFrom(address sender, address recipient, uint256 tokens) external returns(bool);

    //Transfering tokens to another address
    function transferClient(address _client, address recipient, uint256 numTokens) external returns(bool);

    //Event to emit when tokens pass from one to another address
    event Transfer(address indexed from, address indexed to, uint256 value);

    //Even to emit when it's stablished an asignation with the allowance() method
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