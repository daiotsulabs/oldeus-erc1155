//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

/**
 * @title Oldeus seed erc1155 contract
 * @dev Seed nfts smart contract
 * @author Oldeus team
 */
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Abstract1155Factory.sol";

//TODO add wl3 ( vital + stone ) functionality
//TODO change requires to custom error to improve gas efficiency and code readability

contract Seeds1155 is Abstract1155Factory {
    address public multisigWallet;
    address public OLDEUS_721;
    bool public paused = false;
    uint256[5] public nftsMaxSupply = [11, 500, 489, 300, 100];
    uint256 price = 0.2 ether;
    uint256 wlprice = 0.1 ether;
    // phase 1 -> wl | 2 -> public | 3 -> claim serum
    uint8 phase = 1;

    mapping(address => uint256) Claimed;
    mapping(address => bool) specialClaimed;

    //========================================================EVENTS===========================================================

    event sale(address indexed buyer, uint256 indexed tokenId, uint256 price);
    event phaseChanged(uint8 newPhase);

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
    ) ERC1155(_uri) WhitelistManager(_mkroot) {
        _name = _name;
        _symbol = _symbol;
        multisigWallet = _multisigWallet;
    }

    //========================================================PUBLIC===========================================================

    /**
     * @notice Donate eth and mint corresponding NFTs
     */
    function buySeed(uint256 amount) public payable notPaused {
        require(phase == 2, "Public sale not active");

        Claimed[msg.sender] += amount;

        mint(getRandomNumber(), amount);
    }

    /**
     * @notice whitelist mint
     * @param proof merkle proof must be provided to perform correct check
     * @param _type type of whitelist user is claiming to have \ contract is currently in
     * @param amount amount of nfts to buy
     */
    function whitelistBuySeed(
        bytes32[] calldata proof,
        uint256 _type,
        uint256 amount
    ) public payable isWhitelisted(proof, _type) {
        require(phase == 1, "we are not in wl phase");
        require(_type >= 1 && _type <= 2, "incorrect wlType for this phase");
        require(
            userWlMints[msg.sender] <= _type && amount <= _type,
            "minting amount exceeded"
        );

        userWlMints[msg.sender] += amount;

        mint(getRandomNumber(), amount);
    }

    /**
     * @notice function to claim elemental stone or blood vital
     * @param proof hex proof to check address in wl
     * @param _type type of wl to claim, must be 3
     */
    function receiveSpecialNft(bytes32[] calldata proof, uint256 _type)
        public
        payable
        isWhitelisted(proof, _type)
    {
        require(_type == 3, "wl type must be 3");
        require(!specialClaimed[msg.sender]);
        specialClaimed[msg.sender] = true;

        _mint(msg.sender, _type, 1, "");
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

        uint256 tries = 0;

        while (totalSupply(randNum) >= nftsMaxSupply[randNum]) {
            //console.log(randNum, "tries", tries);
            if (tries == 2) revert("not nfts left to mint");
            if (randNum < 2) {
                randNum++;
                tries++;
            } else {
                randNum = 0;
                tries++;
            }
        }

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

    function changePhase(uint8 _newPhase) external onlyOwner {
        phase = _newPhase;
        emit phaseChanged(_newPhase);
    }

    /**
     * @notice withdraw all the funds to the multisig wallet tp later be donated to Ukrainian relief organizations
     */
    function withdrawAll() external onlyOwner {
        (bool succ, ) = multisigWallet.call{value: address(this).balance}("");
        require(succ, "transaction failed");
    }

    //========================================================PRIVATE==========================================================

    /**
     * @notice global mint function used for both whitelist and public mint
     *
     * @param _tokenId the tier of tokens that the sender will receive
     */
    function mint(uint256 _tokenId, uint256 amount) internal {
        require(!paused, "contract is paused");
        require(msg.value >= price * amount, "Invalid value sent");
        require(
            totalSupply(_tokenId) + amount <= nftsMaxSupply[_tokenId],
            "Max supply has been reached"
        );

        _mint(msg.sender, _tokenId, amount, "");
        emit sale(msg.sender, _tokenId, msg.value);
    }
}
