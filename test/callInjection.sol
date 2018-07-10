pragma solidity ^0.4.18;

//test of call injection
contract S1 {
    event Data(uint a1, uint b1, uint c1);
    
    function test(uint8 a, uint8 b, uint8 c) public {
       emit Data(a, b, c);
    }
}


contract S2 {
    
    function run(address addr) public {
    
        require(addr.call(bytes4(keccak256("test(uint8,uint8,uint8)")), 1, 2, 3)); //!!! no space in keccak256()  must to be uint256
        
    }
}
