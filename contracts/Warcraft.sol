// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract OnChainWarcraft {
    enum Fraction {Alliance, Horde, Undead}

    struct Buildings {
        uint256 sawmillLevel;
        uint256 mineLevel;
        uint256 barracksLevel;
    }

    struct Player {
        bool registered;
        Fraction fraction;
        uint256 wood;
        uint256 stone;
        uint256 gold;
        uint256 warriors;
        Buildings buildings;
        uint256 lastClaimTime;
    }

    mapping(address => Player) public players;


    modifier onlyRegistered(){
        require(players[msg.sender].registered, "You are not registered!");
        _;
    }


    function getPlayer(address playerAddress) external view  returns(
        bool registered,
        Fraction fraction,
        uint256 wood,
        uint256 stone,
        uint256 gold,
        uint256 warriors,
        uint256 sawmillLevel,
        uint256 mineLevel,
        uint256 barracksLevel
    ){
        Player storage p = players[playerAddress];
        return(
            p.registered,
            p.fraction,
            p.wood,
            p.stone,
            p.gold,
            p.warriors,
            p.buildings.sawmillLevel,
            p.buildings.mineLevel,
            p.buildings.barracksLevel

        );
    }

}