# @version 0.3.7

owner: public(address)
manager: public(address)

@external
def __init__(_owner: address, _manager: address):
    self.owner = _owner
    self.manager = _manager

@view
@internal
def _only_owner():
    assert msg.sender == self.owner, "You are not authorized"

@view
@internal
def _only_manager():
    assert msg.sender == self.manager, "You are not authorized to manage this contract"
