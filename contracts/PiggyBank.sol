// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract PiggyBank{
    uint256 private money;
    address public owned;

    constructor() {
        owned = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owned, "Only owner can do this!");
        _;
    }

    function addOneToMoney() public {
        money = money + 1;
    }

    function addTotalMoney(uint total) public {
        require(total > 0, "The sum must be > 0!");
        money = money + total;
    }

    function minusOneToMoney() public onlyOwner(){
        require(money > 0, "Bank empty!");
        money = money - 1;

    }

    function minusTotalMoney(uint total) public onlyOwner(){
        require(total > 0, "The sum must be > 0!");
        require(total <= money, "Not enought money for operation");
        money = money - total;
    }

    function nowMoney() public view returns(uint){
        return money;
    }

}