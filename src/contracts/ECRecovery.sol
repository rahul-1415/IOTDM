pragma solidity ^0.5.0;

library ECRecovery {

    function recover(bytes32 _hash, bytes memory _signature)
        internal
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

   
        if (_signature.length != 65) {
            return (address(0));
        }

    
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

    
        if (v < 27) {
            v += 27;
        }

        
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            
            return ecrecover(_hash, v, r, s);
        }
    }

  
    function toEthSignedMessageHash(bytes32 _hash)
        internal
        pure
        returns (bytes32)
    {
       
        return keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
        );
    }
}
