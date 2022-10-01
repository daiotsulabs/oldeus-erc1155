// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "./eip2981/ERC2981ContractWideRoyalties.sol";
import "./WhitelistManager.sol";

abstract contract Abstract1155Factory is
    ERC1155Supply,
    ERC1155Burnable,
    WhitelistManager,
    ERC2981ContractWideRoyalties
{
    string _name;
    string _symbol;

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function setURI(string memory baseURI) external onlyOwner {
        _setURI(baseURI);
    }

    // % is calculated in base 10000 what means 1000 is 10% | 500 -5% etc
    function setRoyalties(address receiver, uint256 percentage)
        external
        onlyOwner
    {
        _setRoyalties(receiver, percentage);
    }

    //Override required by solidity
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
