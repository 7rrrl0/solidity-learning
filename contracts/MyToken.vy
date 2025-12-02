# @version 0.3.7

name: public(String[64])
symbol: public(String[32])
decimals: public(uint256)
totalSupply: public(uint256)
balanceOf: public(HashMap[address, uint256])
allowances: public(HashMap[address, HashMap[address, uint256]])

owner: public(address)
manager: public(address)

event Transfer:
    owner: indexed(address)
    to: indexed(address)
    value: uint256

event Approval:
    spender: indexed(address)
    value: uint256

@external
def __init__(_name: String[64], _symbol: String[32], _decimals: uint256, _initialSupply: uint256):
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
    self.owner = msg.sender
    self.manager = msg.sender
    self._mint(_initialSupply, msg.sender)

@external
def transfer(_amount: uint256, _to: address):
    assert self.balanceOf[msg.sender] >= _amount, "insufficient balance"
    self.balanceOf[msg.sender] -= _amount
    self.balanceOf[_to] += _amount
    log Transfer(msg.sender, _to, _amount)

@external
def approve(_spender: address, _amount: uint256):
    self.allowances[msg.sender][_spender] = _amount
    log Approval(_spender, _amount)

@external
def transferFrom(_owner: address, _to: address, _amount: uint256):
    assert self.allowances[_owner][msg.sender] >= _amount, "insufficient allowance"
    assert self.balanceOf[_owner] >= _amount, "insufficient balance"
    self.allowances[_owner][msg.sender] -= _amount
    self.balanceOf[_owner] -= _amount
    self.balanceOf[_to] += _amount
    log Transfer(_owner, _to, _amount)

@external
def mint(_amount: uint256, _to: address):
    assert msg.sender == self.manager, "You are not authorized to manage this token"
    self._mint(_amount, _to)

@external
def setManager(_manager: address):
    assert msg.sender == self.owner, "You are not authorized"
    self.manager = _manager

@internal
def _mint(_amount: uint256, _to: address):
    self.totalSupply += _amount
    self.balanceOf[_to] += _amount
    log Transfer(empty(address), _to, _amount)
