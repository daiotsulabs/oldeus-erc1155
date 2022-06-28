// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Abstract1155Factory.sol";

abstract contract DutchAuctionManager is Abstract1155Factory {
    uint256 cost = 0.1 ether;
    uint256 minCost = 0.04 ether;

    uint256 private constant duration = 2 hours;
    uint256 public immutable discountRate = 0.0001 ether;
    uint256 public immutable startAt = block.timestamp;
    uint256 public immutable expiresAt = block.timestamp + duration;

    /**
     * @notice function that returns the price
     */
    function getPrice() public view returns (uint256) {
        uint256 timeElapsed = block.timestamp - startAt;
        uint256 discount = discountRate * timeElapsed;
        if (discount > minCost) return minCost;

        return cost - discount;
    }

    /**
     * @notice change all NFTs price
     *
     * @param _newCost new minting price
     */
    function batchSetTierCosts(uint256 _newCost) external onlyOwner {
        cost = _newCost * 1 ether;
    }
}
