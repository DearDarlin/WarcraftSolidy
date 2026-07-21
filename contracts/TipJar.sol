// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract TipJar{

    address public owner;
    uint256 public totalTips;

    struct Tip{
        address from;
        uint256 amount;
        string message;
        uint256 timestamp;
    }

    Tip[] public tips;

    event NewTip(address indexed  from, uint256 amount, string message, uint256 timestamp);
    event Withdraw(address indexed owner, uint256 amount);

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can do this!");
        _;
    }

    function sendTip(string memory _message) public payable {
        require(msg.value > 0, "Tip must be greater that 0");

        tips.push(Tip(msg.sender, msg.value, _message, block.timestamp));
        totalTips += msg.value;

        emit NewTip(msg.sender, msg.value, _message, block.timestamp);
    }

    function getTipsCount() public view returns(uint256){
        return tips.length;
    }

    function getContractBalance() public view returns(uint256){
        return address(this).balance;
    }

    function withdraw() public onlyOwner{
        uint256 balance = address(this).balance;
        require(balance > 0, "No money");

        (bool success, ) = payable(owner). call{value: balance}("");
        require(success, "Transfer failed");


        emit Withdraw(owner, balance);
    }

    receive() external payable {
        totalTips += msg.value;
     }
}