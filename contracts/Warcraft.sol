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

    uint256 public constant WOOD_1_SEC = 1;
    uint256 public constant GOLD_1_SEC = 1;

    uint256 public constant COST = 50;

    event PlayerRegistered(address indexed player, Fraction fraction);
    event ResourceAsk(address indexed player, uint256 getwood, uint256 getgold);


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


    

    function getAllianceDiscount(Fraction _fraction) public pure returns (uint256){
        if (_fraction == Fraction.Alliance){
            return 80;
        }
        return 100;
    }

    function getUndeadBonus(Fraction _fraction) public pure returns (uint256){
        if (_fraction == Fraction.Undead){
            return 120;
        }
        return 100;
    }

    function getHordeBonus(Fraction _fraction) public pure returns (uint256){
        if (_fraction == Fraction.Horde){
            return 120;
        }
        return 100;
    }

    function getResources() external onlyRegistered{
        Player storage p = players[msg.sender];
        uint256 time = block.timestamp - p.lastClaimTime;
        uint256 bonus = getUndeadBonus(p.fraction);

        uint256 getwood = (time*WOOD_1_SEC*p.buildings.sawmillLevel*bonus)/100;
        uint256 getgold = (time*GOLD_1_SEC*p.buildings.mineLevel*bonus)/100;

        p.wood += getwood;
        p.gold += getgold;
        p.lastClaimTime = block.timestamp;

        emit ResourceAsk(msg.sender, getwood, getgold);
    }

    function costUpgreade(address playerAddress, uint256 currentLevel)public view returns (uint256){
        uint256 base = COST * currentLevel;
        uint256 discount = getAllianceDiscount(players[playerAddress].fraction);
        return (base *discount)/100;
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