const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const {
  isCreateTrace,
} = require("hardhat/internal/hardhat-network/stack-traces/message-trace");
const { keccak256 } = ethers.utils;
const generateMerkleTree = require("../merkle-tree");
const { moveBlocks } = require("../utils/move-blocks");

describe("ERC1155-oldeus", function () {
  let contract, interfaceCheckerContract;
  let oldeus, interfaceChecker;
  let owner, addr1, addr2, addrs;
  let tree, merkleRoot;

  const NAME = "test contract";
  const SYMBOL = "OLDEUS";
  const URI = "sampleuri";

  beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    tree = generateMerkleTree([
      { address: owner.address, type: 1 },
      { address: addr1.address, type: 2 },
      { address: addr2.address, type: 1 },
      { address: owner.address, type: 3 },
      { address: owner.address, type: 4 },
    ]);

    merkleRoot = tree.getHexRoot();

    contract = await ethers.getContractFactory("Seeds1155");
    interfaceCheckerContract = await ethers.getContractFactory(
      "CheckInterface"
    );

    interfaceChecker = await interfaceCheckerContract.deploy();

    oldeus = await contract.deploy(
      NAME,
      SYMBOL,
      URI,
      merkleRoot,
      addr1.address
    );
  });

  describe("Deployment", function () {
    // `it` is another Mocha function. This is the one you use to define your
    // tests. It receives the test name, and a callback function.

    // If the callback function is async, Mocha will `await` it.
    it("Should set the right owner", async function () {
      // Expect receives a value, and wraps it in an Assertion object. These
      // objects have a lot of utility methods to assert values.

      // This test expects the owner variable stored in the contract to be equal
      // to our Signer's owner.
      expect(await oldeus.owner()).to.equal(owner.address);
      expect(await oldeus.multisigWallet()).to.equal(addr1.address);
    });
  });

  describe("Erc1155 logic", () => {});

  describe("minting process", () => {
    it("whitelist mint", async () => {
      const msgvalue = { value: ethers.utils.parseEther("0.2") };
      const merkleProof = tree.getHexProof(
        keccak256(
          ethers.utils.solidityPack(["address", "uint256"], [owner.address, 1])
        )
      );

      const merkleProof2 = tree.getHexProof(keccak256(addrs[0].address, 2));

      await expect(
        oldeus.whitelistBuySeed(merkleProof, 1, 1, msgvalue)
      ).to.emit(oldeus, "sale");

      await expect(
        oldeus.connect(addr2).whitelistBuySeed(merkleProof2, 1, 1, msgvalue)
      ).to.be.revertedWith("Not whitelisted");
    });

    it("non whitelist mint", async () => {
      await oldeus.changePhase(2);
      await expect(
        oldeus.buySeed(1, {
          value: ethers.utils.parseEther("0.2"),
        })
      ).to.emit(oldeus, "sale");
    });

    it("mint all tokenId 0 nfts", async () => {
      const value = { value: ethers.utils.parseUnits("0.2", "ether") };
      await oldeus.changePhase(2);

      for (let i = 0; i < 500; i++) {
        const tx = await oldeus.buySeed(1, value);
        const txn = await tx.wait();
      }

      expect(await oldeus.totalSupply(0)).to.be.equal("500");
    });

    it("mint vampire and elemental seeds", async () => {
      await oldeus.changePhase(3);

      const mkproof = tree.getHexProof(
        keccak256(
          ethers.utils.solidityPack(["address", "uint256"], [owner.address, 3])
        )
      );

      const mkproof2 = tree.getHexProof(
        keccak256(
          ethers.utils.solidityPack(["address", "uint256"], [owner.address, 4])
        )
      );

      await oldeus.receiveSpecialNft(mkproof, 3);
      await oldeus.receiveSpecialNft(mkproof2, 4);
      const balOfvampire = (await oldeus.balanceOf(owner.address, 1)) || 1;
      const balOfElemental = await oldeus.balanceOf(owner.address, 2);

      assert(balOfvampire.toString() == "1", "balance of tokenId 1 must be 1");
      assert(
        balOfElemental.toString() === "1",
        "balance of elemental must be 1"
      );
    });

    it("shouldn't allow especial NFt twice", async () => {});

    it("Check contract implements eip2981", async () => {
      const value = await interfaceChecker.check2981(oldeus.address);
      assert(value === true);
    });
  });
});
