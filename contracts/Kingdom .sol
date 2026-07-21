// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract KingdomOfSolidy is AccessControl, Pausable, ReentrancyGuard {

    struct Kingdom {
        string name;
        address owner;
        uint32 level;          
        uint32 happiness;       
        uint32 freeWorkers;    
        uint64 createdAt;      
        uint64 lastCollect;    
        uint256 gold;
        uint256 wood;
        uint256 stone;
        uint256 food;
        uint256 population;
        uint256 armyCount;      
        bool exists;
    }

    struct TroopStats {
        uint256 cost;      
        uint256 attack;    
        uint256 upkeep;    
    }

    struct BuildingInfo {
        uint256 costMultiplier; 
    }

    struct GameEvent {
        EventType eventType;
        uint256 endsAt;
    }

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    bytes32 public constant EVENT_MANAGER_ROLE = keccak256("EVENT_MANAGER_ROLE");

    uint256 private nextKingdomId = 1;

    mapping(uint256 => Kingdom) public kingdoms;
    mapping(address => uint256) public ownerToKingdom;

    enum BuildingType { Sawmill, Mine, GoldMine, Farm, Barracks, Walls, Academy }
    enum TroopType { Swordsman, Archer, Knight }
    enum ResearchType { Military, Engineering, Economy, Agriculture }
    enum ResourceType { Gold, Wood, Stone, Food }
    enum EventType { None, DoubleResources, BuildingDiscount, ArmyDiscount, BattleRewardBoost }

    event GamePaused(address indexed by);
    event GameUnpaused(address indexed by);

    error NotAuthorized();
    error NotKingdomOwner();
    error KingdomDoesNotExist();

    modifier onlyAdmin() {
        if (!hasRole(ADMIN_ROLE, msg.sender)) revert NotAuthorized();
        _;
    }

    modifier onlyModerator() {
        if (!hasRole(MODERATOR_ROLE, msg.sender) && !hasRole(ADMIN_ROLE, msg.sender)) revert NotAuthorized();
        _;
    }

    modifier onlyEventManager() {
        if (!hasRole(EVENT_MANAGER_ROLE, msg.sender) && !hasRole(ADMIN_ROLE, msg.sender)) revert NotAuthorized();
        _;
    }

    modifier kingdomExists(uint256 kingdomId) {
        if (!kingdoms[kingdomId].exists) revert KingdomDoesNotExist();
        _;
    }

    modifier onlyKingdomOwner(uint256 kingdomId) {
        if (kingdoms[kingdomId].owner != msg.sender) revert NotKingdomOwner();
        _;
    }

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function pause() external onlyAdmin {
        _pause();
        emit GamePaused(msg.sender);
    }

    function unpause() external onlyAdmin {
        _unpause();
        emit GameUnpaused(msg.sender);
    }

    function grantModeratorRole(address account) external onlyAdmin {
        _grantRole(MODERATOR_ROLE, account);
    }

    function grantEventManagerRole(address account) external onlyAdmin {
        _grantRole(EVENT_MANAGER_ROLE, account);
    }
}