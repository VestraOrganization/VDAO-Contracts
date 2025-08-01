// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Collaboration is Ownable, ReentrancyGuard {

    error MaxPoolLimit(uint8 catId, uint256 pool, uint256 limit);

    event DistributedReward(uint256 reward);
    event Claim(address indexed account, uint256 amount);
    event Withdraw(address indexed owner, uint256 amount);


    using SafeERC20 for IERC20;

    IERC20 public token;

    uint256 internal _totalClaim;
    struct Category {
        uint8 id;
        string name;
        uint256 pool;
        uint256 maxReward;
        uint256 totalRewards; // Total Rewards Defined	
    }

    Category[] public categories;

    struct Reward {
        uint256 total;
        uint256 current;
    }
    mapping (address => Reward) internal _accountRewards;
    constructor(
        address initialOwner,
        address tokenAddress
    ) Ownable(initialOwner) {
        require(initialOwner != address(0), "Owner's address cannot be zero");
        require(tokenAddress != address(0), "Token address cannot be zero");

        token = IERC20(tokenAddress);
    }

    function createCategory(uint8 catId, string memory name, uint256 pool, uint256 maxReward) external onlyOwner() {
        require(categories.length < 4, "All Categories Have Been Defined");
        
        for (uint i = 0; i < categories.length; i++) {
            require(categories[i].id != catId, "Category ID Already Exists");
        }
        
        Category memory cat;

        cat.id = catId;
        cat.name = name;
        cat.pool = pool;
        cat.maxReward = maxReward;

        categories.push(cat);
    }


    function setRewards(uint8 catId, address[] memory accounts, uint256[] memory rewards) external onlyOwner() {
        require(accounts.length == rewards.length,"Account and Reward Count Mismatch");
        
        Category storage cat = categories[catId]; 

        uint256 _distributedReward = 0;
        for (uint i = 0; i < accounts.length; i++) {
            uint256 _accountReward = rewards[i];
            require(_accountReward <= cat.maxReward, "Reward Exceeds Maximum Limit");
            _accountRewards[accounts[i]].current += _accountReward;
            _distributedReward += _accountReward;
        }

        if (_distributedReward + cat.totalRewards > cat.pool) {
            revert MaxPoolLimit(catId, cat.pool, _distributedReward + cat.totalRewards); 
        }

        cat.totalRewards += _distributedReward; 

        emit DistributedReward(_distributedReward);
    }

    function claim() external nonReentrant() {
        uint256 _reward = _accountRewards[_msgSender()].current;
        require(_reward > 0,"No Earned Rewards");
        _accountRewards[_msgSender()].current = 0;
        _accountRewards[_msgSender()].total += _reward;

        _totalClaim += _reward;

        token.safeTransfer(_msgSender(), _reward);
        emit Claim(_msgSender(), _reward); 
    }

    function accountInfo(address account) external view returns(uint256 totalReward, uint256 currentReward){
        return (_accountRewards[account].total, _accountRewards[account].current);
    }

    function getAllCategory() external view returns(Category[] memory){
        return categories; 
    }

    function info() external view returns(uint256 totalSetReward, uint256 totalClaim){
        for (uint i = 0; i < categories.length; i++) {
            totalSetReward += categories[i].totalRewards; 
        }
        totalClaim = _totalClaim;
    }

    function emergencyWithdraw() external onlyOwner() {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No Tokens Available For Withdrawal");
        token.safeTransfer(owner(), balance);

        emit Withdraw(owner(), balance);
    }

}
