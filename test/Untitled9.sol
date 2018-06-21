pragma solidity ^0.4.16;

contract testContract {

    uint public value;
    function testContract(uint8 _p) {
        value = _p;
        if(_p > 5) revert();
        
    }

    function setP(uint _n) payable {
        value = _n;
        assert(value <= 5);
        value++;
    }

    function setNP(uint _n) {
        value = _n;
    }

    function get () constant returns (uint) {
        return value;
    }
}