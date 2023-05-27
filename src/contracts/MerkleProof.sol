pragma solidity ^0.5.0;

/**
 * @title MerkleProof
 * @dev Merkle proof verification based on https://github.com/ameensol/merkle-tree-solidity/blob/master/src/MerkleProof.sol
 * Source: https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/MerkleProof.sol
 */
library MerkleProof {
    /**
     * @dev Verifies a Merkle proof proving the existence of a leaf in a Merkle tree. Assumes that each pair of leaves
     * and each pair of pre-images are sorted.
     * @param _proof Merkle proof containing sibling hashes on the branch from the leaf to the root of the Merkle tree
     * @param _root Merkle root
     * @param _leaf Leaf of Merkle tree
     */
    function verifyProof(
        bytes32[] memory _proof,
        bytes32 _root,
        bytes32 _leaf
    )
        internal
        pure
        returns (bool)
    {
        bytes32 computedHash = _leaf;

        for (uint256 i = 0; i < _proof.length; i++) {
            bytes32 proofElement = _proof[i];

            if (computedHash < proofElement) {
               
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        
        return computedHash == _root;
    }
}