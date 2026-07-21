// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


contract Counter {
    uint256 private  count;
    address public owner;

    constructor(){
        owner = msg.sender;
    }

    function get() public view returns (uint256){
        require(msg.sender == owner, "Only owner can call this function");
        return count;
    }

    function increm() public {
        require(msg.sender == owner, "Only owner can call this function");
        require(count < 100, "Count cannot exceed 100");
        count = count + 1;
    }

    function decrem() public {
        require(msg.sender == owner, "Only owner can call this function");
        require(count > 0, "Count cannot be less than 0");
        count = count - 1;
    }
    
}