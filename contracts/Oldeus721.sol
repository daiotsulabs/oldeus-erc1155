// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./eip2981/ERC2981ContractWideRoyalties.sol";

interface OldeusSeeds is IERC1155 {
    function burnSeed(address account, uint256[] memory tokenIds) external;
}

//? -> allow human burning from this contract

contract Oldeus is
    ERC721,
    ReentrancyGuard,
    ERC2981ContractWideRoyalties,
    Ownable
{
    OldeusSeeds public SeedsContract;

    uint32 maxSupply = 5555;
    uint32 currSupply = 0;

    constructor(
        string memory _name,
        string memory _symbol,
        address _seedsContract
    ) ERC721(_name, _symbol) {
        SeedsContract = OldeusSeeds(_seedsContract);
        _setRoyalties(msg.sender, 500);
    }

    function redeemEstarian(uint256[] memory tokenIds) external nonReentrant {
        SeedsContract.burnSeed(msg.sender, tokenIds);

        _safeMint(msg.sender, currSupply + 1);
    }

    // Burn tokenId 0 + 1
    function redeemVampire(uint256[] memory tokenIds) external nonReentrant {
        SeedsContract.burnSeed(msg.sender, tokenIds);
    }

    function redeemElemental(uint256[] memory tokenIds) external nonReentrant {
        SeedsContract.burnSeed(msg.sender, tokenIds);
    }

    // % is calculated in base 10000 what means 1000 is 10% | 500 -5% etc
    function setRoyalties(address receiver, uint256 percentage)
        external
        onlyOwner
    {
        _setRoyalties(receiver, percentage);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
