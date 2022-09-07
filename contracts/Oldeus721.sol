// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface OldeusSeeds is IERC1155 {
    function burnSeed(address account, uint256[] memory tokenIds) external;
}

contract Oldeus is ERC721, ReentrancyGuard {
    OldeusSeeds public SeedsContract;

    uint32 maxSupply = 5555;
    uint32 currSupply = 0;

    constructor(
        string memory _name,
        string memory _symbol,
        address _seedsContract
    ) ERC721(_name, _symbol) {
        SeedsContract = OldeusSeeds(_seedsContract);
    }

    function redeemEstarian(uint256[] memory tokenIds) external nonReentrant {
        SeedsContract.burnSeed(msg.sender, tokenIds);

        _safeMint(msg.sender, currSupply + 1);
    }
}
