// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SecureTokenVault is Ownable, AccessControl, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardToken;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant AUDITOR_ROLE = keccak256("AUDITOR_ROLE");

    uint256 public constant REWARD_INTERVAL = 60; 
    uint256 public constant UNSTAKE_COOLDOWN = 5 minutes;

    uint256 public minStakingAmount;
    uint256 public baseRewardRate; 

    enum Tier { Bronze, Silver, Gold, Diamond }
    enum LockPeriod { None, SevenDays, ThirtyDays, NinetyDays }

    struct StakeInfo {
        uint256 amount;
        uint256 startTime;
        uint256 lastClaimTime;
        uint256 totalRewardsClaimed;
        uint256 lockEndTime;
        LockPeriod lockPeriod;
    }

    struct GlobalStats {
        uint256 totalUsers;
        uint256 totalCurrentlyStaked;
        uint256 totalUnstaked;
        uint256 totalRewardsPaid;
        uint256 stakeOperations;
        uint256 unstakeOperations;
        uint256 claimOperations;
    }

    GlobalStats private stats;
    mapping(address => StakeInfo) private userStakes;
    mapping(address => bool) private hasStakedBefore;


    event Staked(address indexed user, uint256 amount, LockPeriod period, uint256 lockEndTime);
    event StakeIncreased(address indexed user, uint256 additionalAmount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event StakingPaused(address account);
    event StakingUnpaused(address account);
    event ParametersChanged(uint256 newMinAmount, uint256 newRewardRate);
    event RoleGrantedCustom(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevokedCustom(bytes32 indexed role, address indexed account, address indexed sender);


    constructor(address _stakingToken, address _rewardToken) Ownable(msg.sender) {
        require(_stakingToken != address(0), "Invalid staking token");
        require(_rewardToken != address(0), "Invalid reward token");

        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(AUDITOR_ROLE, msg.sender);
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        _;
    }

    modifier onlyAuditor() {
        require(hasRole(AUDITOR_ROLE, msg.sender) || hasRole(ADMIN_ROLE, msg.sender), "Caller is not an auditor");
        _;
    }

    function getGlobalStats() external view onlyAuditor returns (GlobalStats memory){
        return stats;
    }
     
    function getUserTier(address _user) public view returns (Tier){
        uint256 amount = userStakes[_user].amount;
        if (amount >= 1000 * 10**18){
            return Tier.Diamond;
        }
        if (amount >= 500 * 10**18){
            return Tier.Gold;
        }
        if (amount >= 100 * 10**18){
            return Tier.Silver;
        }
        return Tier.Bronze;

    }

    function _getTierMultiplier(Tier _tier) private pure returns (uint256){
        if (_tier == Tier.Diamond) {
            return 200;
        }
        if (_tier == Tier.Gold) {
            return 150;
        }
        if (_tier == Tier.Silver) {
            return 120;
        }
        return 100;
    }

    function _getLockMultiplier(LockPeriod _period) private pure returns (uint256){
        if (_period == LockPeriod.NinetyDays) {
            return 300;
        }
        if (_period == LockPeriod.ThirtyDays){
            return 200;
        }
        if (_period == LockPeriod.SevenDays){
            return 130;
        }

        return 100;

    }

    function _getLockDuration(LockPeriod _period) private pure returns (uint256){
        if (_period == LockPeriod.SevenDays) {
            return 7 days;
        }
        if (_period == LockPeriod.ThirtyDays){
            return 30 days;
        }
        if (_period == LockPeriod.NinetyDays) {
            return 90 days;
        }
        return 0;
    }
    
    

    function stake(uint256 _amount, LockPeriod _period) external whenNotPaused nonReentrant {
        require(_amount > 0, "Cannot stake 0 tokens");
        
        StakeInfo storage userStake = userStakes[msg.sender];
        
        if (userStake.amount == 0) {
            require(_amount >= minStakingAmount, "Amount less than minimum");
            
            uint256 duration = _getLockDuration(_period);
            userStake.amount = _amount;
            userStake.startTime = block.timestamp;
            userStake.lastClaimTime = block.timestamp;
            userStake.lockPeriod = _period;
            userStake.lockEndTime = block.timestamp + duration;

            if (!hasStakedBefore[msg.sender]) {
                hasStakedBefore[msg.sender] = true;
                stats.totalUsers++;
            }
            
            emit Staked(msg.sender, _amount, _period, userStake.lockEndTime);
        } else {

            _claimReward(msg.sender);

            userStake.amount += _amount;
            userStake.lastClaimTime = block.timestamp;

            emit StakeIncreased(msg.sender, _amount);
        }

        stats.totalCurrentlyStaked += _amount;
        stats.stakeOperations++;

        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function unstake() external whenNotPaused nonReentrant {
        StakeInfo storage userStake = userStakes[msg.sender];
        uint256 stakedAmount = userStake.amount;

        require(stakedAmount > 0, "No active stake found");
        require(block.timestamp >= userStake.lockEndTime, "Tokens are currently locked");
        require(block.timestamp >= userStake.lastClaimTime + UNSTAKE_COOLDOWN, "Unstake cooldown active");

        _claimReward(msg.sender);

        delete userStakes[msg.sender];

        stats.totalCurrentlyStaked -= stakedAmount;
        stats.totalUnstaked += stakedAmount;
        stats.unstakeOperations++;

        emit Unstaked(msg.sender, stakedAmount);
        stakingToken.safeTransfer(msg.sender, stakedAmount);
    }

    function claimReward() external whenNotPaused nonReentrant {
        require(userStakes[msg.sender].amount > 0, "No active stake");
        _claimReward(msg.sender);
    }

    function _claimReward(address _user) internal {
        StakeInfo storage userStake = userStakes[_user];
        uint256 reward = calculateReward(_user);

        uint256 timePassed = block.timestamp - userStake.lastClaimTime;
        uint256 fullIntervals = timePassed / REWARD_INTERVAL;
        
        if (fullIntervals > 0) {
            userStake.lastClaimTime += fullIntervals * REWARD_INTERVAL;
        }

        if (reward > 0) {
            userStake.totalRewardsClaimed += reward;
            stats.totalRewardsPaid += reward;
            stats.claimOperations++;

            emit RewardClaimed(_user, reward);
            rewardToken.safeTransfer(_user, reward);
        }
    }

    function calculateReward(address _user) public view returns (uint256) {
        StakeInfo memory userStake = userStakes[_user];
        if (userStake.amount == 0) return 0;

        uint256 timePassed = block.timestamp - userStake.lastClaimTime;
        uint256 fullIntervals = timePassed / REWARD_INTERVAL;
        if (fullIntervals == 0) return 0;

        Tier userTier = getUserTier(_user);
        uint256 tierMultiplier = _getTierMultiplier(userTier); 
        uint256 lockMultiplier = _getLockMultiplier(userStake.lockPeriod); 

        uint256 reward = (userStake.amount * baseRewardRate * fullIntervals * tierMultiplier * lockMultiplier) / 10000;
        return reward;
    }

    function setPaused(bool _paused) external onlyAdmin {
        if (_paused) {
            _pause();
            emit StakingPaused(msg.sender);
        } else {
            _unpause();
            emit StakingUnpaused(msg.sender);
        }
    }

    function updateParameters(uint256 _newMinAmount, uint256 _newRewardRate) external onlyAdmin {
        minStakingAmount = _newMinAmount;
        baseRewardRate = _newRewardRate;
        emit ParametersChanged(_newMinAmount, _newRewardRate);
    }


    function getUserStakeInfo(address _user) external view onlyAuditor returns (StakeInfo memory) {
        return userStakes[_user];
    }

    
    
}