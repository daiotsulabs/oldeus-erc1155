// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Abstract1155Factory.sol";

abstract contract DutchAuctionManager is Abstract1155Factory {
    uint256[3] public tierCost = [0.1 ether, 0.2 ether, 0.3 ether];
    uint256[3] public tierMinCost = [0.04 ether, 0.08 ether, 0.12 ether];

    uint256 private constant duration = 2 hours;
    uint256 public immutable discountRate = 0.0001 ether;
    uint256 public immutable startAt = block.timestamp;
    uint256 public immutable expiresAt = block.timestamp + duration;

    /**
     * @notice function that returns the price of an specific tokenID
     * @param _index index of the token in the tiercos array
     */
    function getPrice(uint256 _index) public view returns (uint256) {
        //TODO min price + never let negative number occur
        require(
            _index >= 0 && _index <= 2,
            "token id out of range or not buyable"
        );

        uint256 timeElapsed = block.timestamp - startAt;
        uint256 discount = discountRate * timeElapsed;
        if (discount > tierMinCost[_index]) return tierMinCost[_index];

        return tierCost[_index] - discount;
    }

    /**
     * @notice change all NFTs price
     *
     * @param _newCosts array of new Costs [tier1, tier2, tier3]
     */
    function batchSetTierCosts(uint256[3] memory _newCosts) external onlyOwner {
        for (uint256 i = 0; i < _newCosts.length; ++i)
            tierCost[i] = _newCosts[i];
    }
}
