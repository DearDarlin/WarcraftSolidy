// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract PiggyBank{
    uint256 private money;
    address public owned;

    uint256 public goals;
    bool public isOpen;

    mapping(address => uint256) private usersMoney;

    uint256 public allDeposits;
    uint256 public allWithdrawals;

    address public leader;
    uint256 public biggestContribution;


    constructor() {
        owned = msg.sender;
        isOpen = true;
        goals = 1000;
    }

    modifier onlyOwner(){
        require(msg.sender == owned, "Only owner can do this!");
        _;
    }

    function addOneToMoney() public {
        require(isOpen, "Sorry! Bank closed!");
        money = money + 1;
        usersMoney[msg.sender] += 1;
        allDeposits++;

        if (1 > biggestContribution){
            biggestContribution = usersMoney[msg.sender];
            leader = msg.sender;
        }

    }

    function addTotalMoney(uint256 total) public {
        require(total > 0, "The sum must be > 0!");
        require(isOpen, "Sorry! Bank closed!");
        money = money + total;
        usersMoney[msg.sender] += total;
        allDeposits++;

        if (total > biggestContribution){
            biggestContribution = usersMoney[msg.sender];
            leader = msg.sender;
        }
    }

    function minusOneToMoney() public onlyOwner{
        require(money > 0, "Bank empty!");
        money = money - 1;
        allWithdrawals++;
    }

    function minusTotalMoney(uint total) public onlyOwner{
        require(total > 0, "The sum must be > 0!");
        require(total <= money, "Not enought money for operation");
        money = money - total;
        allWithdrawals++;
    }

    function nowMoney() public view returns(uint256){
        return money;
    }

    function closeBank() public onlyOwner{
        require(isOpen, "Bank is already closed!");
        isOpen = false;
    }

    function openBank() public onlyOwner{
        require(!isOpen, "Bank is already open!");
        isOpen = true;
    }

    function usersMoneyView(address user) public view returns(uint256){
        return usersMoney[user];
    }
    
    function changeGoal(uint256 newGoal) public onlyOwner{
        require(newGoal > 0, "New goal must be > 0!");
        goals = newGoal;
    }

    function checkGoal() public view returns(bool){
        return money>= goals;
    }

    function transferOwner(address newOwner) public onlyOwner{
        require(newOwner != address(0), "Invalid addres!");
        owned = newOwner;
    }

    function takeLeader() public view returns (address){
        return leader;
    }

    function takeBiggestContribution() public view returns (uint256){
        return biggestContribution;
    }




}