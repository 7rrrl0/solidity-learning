# @version 0.3.7

from vyper.interfaces import ERC20

interface IMyToken:
    def transfer(_amount: uint256, _to: address): nonpayable
    def transferFrom(_owner: address, _to: address, _amount: uint256): nonpayable
    def mint(_amount: uint256, _to: address): nonpayable

stakingToken: public(IMyToken)
lastClaimedBlock: public(HashMap[address, uint256])
defaultRewardPerBlock: public(uint256)
rewardPerBlock: public(uint256)
staked: public(HashMap[address, uint256])
totalStaked: public(uint256)

owner: public(address)
manager: public(address)

event Staked:
    _owner: indexed(address)
    _amount: uint256

event Withdraw:
    _amount: uint256
    _to: indexed(address)

@external
def __init__(_stakingToken: address):
    self.stakingToken = IMyToken(_stakingToken)
    self.owner = msg.sender
    self.manager = msg.sender
    self.defaultRewardPerBlock = 1000000000000000000  # 1 * 10 ** 18
    self.rewardPerBlock = self.defaultRewardPerBlock

@internal
def _update_reward(_to: address):
    if self.staked[_to] > 0:
        blocks: uint256 = block.number - self.lastClaimedBlock[_to]
        reward: uint256 = (blocks * self.rewardPerBlock * self.staked[_to]) / self.totalStaked
        self.stakingToken.mint(reward, _to)
    self.lastClaimedBlock[_to] = block.number

@external
def setRewardPerBlock(_amount: uint256):
    assert msg.sender == self.manager, "You are not authorized to manage this contract"
    self.rewardPerBlock = _amount

@external
def stake(_amount: uint256):
    self._update_reward(msg.sender)
    assert _amount > 0, "cannot stake 0 amount"
    self.stakingToken.transferFrom(msg.sender, self, _amount)
    self.staked[msg.sender] += _amount
    self.totalStaked += _amount
    log Staked(msg.sender, _amount)

@external
def withdraw(_amount: uint256):
    self._update_reward(msg.sender)
    assert self.staked[msg.sender] >= _amount, "insufficient staked token"
    self.stakingToken.transfer(_amount, msg.sender)
    self.staked[msg.sender] -= _amount
    self.totalStaked -= _amount
    log Withdraw(_amount, msg.sender)
