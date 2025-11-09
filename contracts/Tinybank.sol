// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./MultiManagedAccess.sol";

interface IMyToken {
    function transfer(uint256 amount, address to) external;

    function transferFrom(address from, address to, uint256 amount) external;

    function mint(uint256 amount, address to) external;
}

contract Tinybank is MultiManagedAccess {
    event Staked(address, uint256 amount);
    event Withdraw(uint256, address);

    IMyToken public stakingToken;
    
    mapping(address => uint256) public lastClaimedBlock;
    
    uint256 public defaultRewardPerBlock = 1 * 10 ** 18;
    uint256 public rewardPerBlock;

    mapping(address => uint256) public staked;
    uint256 public totalStaked;

    constructor(IMyToken _stakingToken, address[] memory _managers) MultiManagedAccess(msg.sender, _managers, _managers.length) {
        require(_managers.length >= 3, "At least 3 managers required");
        stakingToken = _stakingToken;
        rewardPerBlock = defaultRewardPerBlock;
    }

    modifier upDateReward(address to) {
        if (staked[to] > 0) {
            uint256 blocks = block.number - lastClaimedBlock[to];
            uint256 reward = (blocks * rewardPerBlock * staked[to]) / totalStaked;
            stakingToken.mint(reward, to);
        }
        lastClaimedBlock[to] = block.number;
        _;
    }

    function setRewardPerBlock(uint256 _amount) external onlyAllConfirmed {
        rewardPerBlock = _amount;
    }
    
    function stake(uint256 _amount) external upDateReward(msg.sender) {
        require(_amount > 0, "cannot stake 0 amount");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        staked[msg.sender] += _amount;  
        totalStaked += _amount;
        emit Staked(msg.sender, _amount);
    }
    
    function withdraw(uint256 _amount) external upDateReward(msg.sender) {
        require(staked[msg.sender] >= _amount, "insufficient staked token");
        stakingToken.transfer(_amount, msg.sender);
        staked[msg.sender] -= _amount;
        totalStaked -= _amount;
        emit Withdraw(_amount, msg.sender);
    }
}

