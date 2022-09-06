// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WhitelistManager is Ownable {
    using MerkleProof for bytes32[];

    bytes32 private _merkleRoot;
    mapping(address => uint256) userWlMints;

    constructor(bytes32 _mkRoot) {
        _merkleRoot = _mkRoot;
    }

    /**
     * @notice check if a user is whitelisted
     * @param proof proof required to verify
     * @param wltype type of whitelist the user owns (1 | 2 | 3)
     */
    modifier isWhitelisted(bytes32[] calldata proof, uint256 wltype) {
        require(
            MerkleProof.verify(
                proof,
                _merkleRoot,
                keccak256(abi.encodePacked(msg.sender, wltype))
            ),
            "Not whitelisted"
        );

        _;
    }

    function changeRoot(bytes32 _newRoot) external onlyOwner {
        _merkleRoot = _newRoot;
    }
}
