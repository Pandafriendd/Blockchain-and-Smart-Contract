pragma solidity ^0.4.18;

contract HelloCoin {
    string public name = 'HelloCoin';
	string public symbol = 'hc';
	mapping (address => uint) balances;
	event Transfer(address _from, address _to, uint256 _value);

	constructor() public {
		balances[msg.sender] = 10000;
	}

	function sendCoin(address _receiver, uint _amount) public returns(bool sufficient) {
		if (balances[msg.sender] < _amount) return false;
		balances[msg.sender] -= _amount;
		balances[_receiver] += _amount;
		emit Transfer(msg.sender, _receiver, _amount);
		return true;
	}

	function getBalance(address _addr) public view returns(uint) {
		return balances[_addr];
	}
}