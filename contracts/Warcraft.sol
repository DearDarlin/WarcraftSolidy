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

    uint256 public constant INITIAL_WOOD = 100;
    uint256 public constant INITIAL_STONE = 100;
    uint256 public constant INITIAL_GOLD = 100;

    event PlayerRegistered(address indexed player, Fraction fraction);


    modifier onlyRegistered(){
        require(players[msg.sender].registered, "You are not registered!");
        _;
    }

    function register(Fraction _fraction) external {
        require(!players[msg.sender].registered, "Already registered");

        players[msg.sender] = Player({
            registered: true,
            fraction: _fraction,
            wood: INITIAL_WOOD,
            stone: INITIAL_STONE,
            gold: INITIAL_GOLD,
            warriors: 0,
            buildings: Buildings({
                sawmillLevel: 1, 
                mineLevel: 1, 
                barracksLevel: 1}),
            lastClaimTime: block.timestamp
        });

        emit PlayerRegistered(msg.sender, _fraction);
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