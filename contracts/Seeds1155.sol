//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @title Oldeus seed erc1155 contract
 * @dev Seed nfts smart contract
 * @author Oldeus team
 */

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Abstract1155Factory.sol";

contract Seeds1155 is Abstract1155Factory {
    address public multisigWallet;
    address public OLDEUS_721;
    bool public paused = false;
    uint256[5] public nftsMaxSupply = [5555, 5555, 5555, 300, 100];
    uint256[3] public tierCost = [0.1 ether, 0.2 ether, 0.3 ether];

    //========================================================EVENTS===========================================================

    /**
     * @notice event that fires when funds are withdrawn
     * @param to address that receives the contract balance
     * @param value value sent to the address
     */
    event Withdrawn(address to, uint256 value);

    /**
     * @notice event that fires when the OLDEUS_721 address changes
     * @param _address new address of the contract
     * @param timestamp block.timestamp
     */
    event OldeusContractChanged(address _address, uint256 timestamp);

    //========================================================MODIFIERS========================================================

    modifier notPaused() {
        require(paused == false, "Contract is paused!");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address _multisigWallet
    ) ERC1155(_uri) {
        _name = _name;
        _symbol = _symbol;
        multisigWallet = _multisigWallet;
        _mint(msg.sender, 0, 1, "");
    }

    //========================================================PUBLIC===========================================================

    /**
     * @notice Donate eth and mint corresponding NFTs
     */
    function donate() public payable notPaused {
        uint256 amountDonated = msg.value;
        uint256 tier = 0;
        if (amountDonated >= tierCost[2]) tier = 3;
        else if (amountDonated >= tierCost[1]) tier = 2;
        else {
            require(
                amountDonated >= tierCost[0],
                "Amount donated must be higher"
            );
            tier = 1;
        }
        mint(tier);
    }

    /**
     * @notice giveaway nft of the selected tier to receiver
     *
     * @param nftTier set the nft to be minted
     * @param receiver address to receive the NFT
     */
    function giveAway(uint256 nftTier, address receiver) public onlyOwner {
        require(
            totalSupply(nftTier) + 1 <= nftsMaxSupply[nftTier],
            "Max supply has been reached"
        );
        _mint(receiver, nftTier, 1, "");
    }

    /**
     * @notice withdraw all the funds to the multisig wallet tp later be donated to Ukrainian relief organizations
     */
    function withdrawAll() public payable onlyOwner {
        (bool succ, ) = multisigWallet.call{value: address(this).balance}("");
        require(succ, "transaction failed");
        emit Withdrawn(multisigWallet, address(this).balance);
    }

    /**
     * @notice returns the  uri for the selected NFT
     *
     * @param _id NFT id
     */
    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "URI: nonexistent token");
        return
            string(
                abi.encodePacked(
                    super.uri(_id),
                    "/",
                    Strings.toString(_id),
                    ".json"
                )
            );
    }

    /**
     * @notice returns the  uri for the selected NFT
     *
     * @param newMultisig_ NFT id
     */
    function changeMultisig(address newMultisig_) public onlyOwner {
        multisigWallet = newMultisig_;
    }

    //========================================================EXTERNAL=========================================================

    /**
     * @notice change the supply of the selected tier
     *
     * @param _tier tier to change max supply for
     * @param _newMaxAmount Max supply to be assigned to the nft
     */
    function setMaxSupply(uint256 _tier, uint256 _newMaxAmount)
        external
        onlyOwner
    {
        nftsMaxSupply[_tier] = _newMaxAmount;
    }

    /**
     * @notice change all NFTs maxSupply
     *
     * @param _newSupplies array of new Supplies [tier1, tier2, tier3]
     */
    function batchSetMaxSupply(uint256[3] memory _newSupplies)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _newSupplies.length; ++i)
            nftsMaxSupply[i] = _newSupplies[i];
    }

    /**
     * @notice change all NFTs maxSupply
     *
     * @param _newCosts array of new Costs [tier1, tier2, tier3]
     */
    function batchSetTierCosts(uint256[3] memory _newCosts) external onlyOwner {
        for (uint256 i = 0; i < _newCosts.length; ++i)
            tierCost[i] = _newCosts[i];
    }

    /**
     * @notice function to pause and unpause minting
     */
    function flipPause() external onlyOwner {
        paused = !paused;
    }

    /**
     * @notice function to set the OLDEUS_721 address
     * @param _address address of OLDEUS_721 contract
     */
    function _setOldeus721Address(address _address) external onlyOwner {
        OLDEUS_721 = _address;
        emit OldeusContractChanged(_address, block.timestamp);
    }

    /**
     * @notice function that allows OLDEUS_NFT contract to burn a token and reedeem the erc721
     * OLDEUS_721 contract must have allowance to burn required tokens
     * @param account account that will burn the token
     * @param tokenIds array of token ids that will be burned
     *   Only 1 token burned === elve, beast, human
     *  2 tokenids minted === special nft minted
     */
    function burn(address account, uint16[] memory tokenIds) external {
        require(msg.sender == OLDEUS_721, "invalid address");

        for (uint16 i = 0; i < tokenIds.length; ) {
            _burn(account, tokenIds[i], 1);

            unchecked {
                ++i;
            }
        }
    }

    //========================================================PRIVATE==========================================================

    /**
     * @notice global mint function used for both whitelist and public mint
     *
     * @param _tier the tier of tokens that the sender will receive
     */
    function mint(uint256 _tier) internal {
        require(!paused, "Contract is paused");

        require(
            totalSupply(_tier) + 1 <= nftsMaxSupply[_tier],
            "Max supply has been reached"
        );

        _mint(msg.sender, _tier, 1, "");
    }
}
