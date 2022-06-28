//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

/**
 * @title Oldeus seed erc1155 contract
 * @dev Seed nfts smart contract
 * @author Oldeus team
 */

import "hardhat/console.sol";
import "./DutchAuctionManager.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./Abstract1155Factory.sol";

contract Seeds1155 is DutchAuctionManager {
    //TODO merkle whitelist implementation in the mint function
    using MerkleProof for bytes32[];

    bytes32 private _merkleRoot;
    address public multisigWallet;
    address public OLDEUS_721;
    bool public paused = false;
    bool public whitelistPhase = true;
    uint256[5] public nftsMaxSupply = [5555, 5555, 5555, 300, 100];

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
        bytes32 _mkroot,
        address _multisigWallet
    ) ERC1155(_uri) {
        _name = _name;
        _symbol = _symbol;
        multisigWallet = _multisigWallet;
        _merkleRoot = _mkroot;
    }

    //========================================================PUBLIC===========================================================

    /**
     * @notice Donate eth and mint corresponding NFTs
     */
    function buySeed(uint256 _seed) public payable notPaused {
        require(!whitelistPhase, "whitelist phase currently active");
        require(!paused, "contract is paused");
        require(msg.value >= getPrice(_seed), "Invalid value sent");
        mint(_seed);
    }

    function whitelistBuySeed(uint256 _seed, bytes32[] calldata proof)
        public
        payable
    {
        //TODO if needed tore in the merkle proof address -> quantity and allow people to mint multiple nfts
        require(
            MerkleProof.verify(
                proof,
                _merkleRoot,
                keccak256(abi.encodePacked(_msgSender()))
            ),
            "Not whitelisted"
        );

        mint(_seed);
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

    function getRandomNumber() public view returns (uint256) {
        uint256 randNum = uint256(
            keccak256(abi.encodePacked(block.difficulty, block.timestamp))
        ) % 3;

        return randNum;
    }

    //========================================================EXTERNAL=========================================================

    function claimRareSerum(uint256 _id, uint256 _amount) external onlyOwner {
        //TODO if we do it by whitelist generate new merkleRoot
        // if not create admin minting or whitelist by mapping
    }

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
     * @notice Set root for merkle tree whitelist
     * @param newRoot merkle root to be set
     */
    function setMerkleRoot(bytes32 newRoot) external onlyOwner {
        _merkleRoot = newRoot;
    }

    /**
     * @notice function to pause and unpause minting
     */
    function flipPause() external onlyOwner {
        paused = !paused;
    }

    /**
     * @notice function to
     */
    function flipWhitelistPhase() external onlyOwner {
        whitelistPhase = !whitelistPhase;
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

    /**
     * @notice withdraw all the funds to the multisig wallet tp later be donated to Ukrainian relief organizations
     */
    function withdrawAll() external onlyOwner {
        (bool succ, ) = multisigWallet.call{value: address(this).balance}("");
        require(succ, "transaction failed");
        emit Withdrawn(multisigWallet, address(this).balance);
    }

    //========================================================PRIVATE==========================================================

    /**
     * @notice global mint function used for both whitelist and public mint
     *
     * @param _tokenId the tier of tokens that the sender will receive
     */
    function mint(uint256 _tokenId) internal {
        require(
            totalSupply(_tokenId) + 1 <= nftsMaxSupply[_tokenId],
            "Max supply has been reached"
        );

        _mint(msg.sender, _tokenId, 1, "");
    }
}
