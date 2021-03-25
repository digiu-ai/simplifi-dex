pragma solidity ^0.8.0;

interface IBridge {
     function transmitRequest(bytes memory owner, address spender) external  returns (bytes32);
}
    