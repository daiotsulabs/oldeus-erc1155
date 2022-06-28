const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { keccak256 } = ethers.utils;
const generateMerkleTree = require("../merkle-tree");
const { moveBlocks } = require("../utils/move-blocks");

describe("ERC1155-oldeus", function () {
  let contract;
  let oldeus;
  let owner, addr1, addr2, addrs;
  let tree, merkleRoot;

  const NAME = "test contract";
  const SYMBOL = "OLDEUS";
  const URI = "sampleuri";

  beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    tree = generateMerkleTree([owner, addr1, addr2]);
    contract = await ethers.getContractFactory("Seeds1155");

    oldeus = await contract.deploy(
      NAME,
      SYMBOL,
      URI,
      tree.getHexRoot(),
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

  describe("dutch auction", function () {
    it("Should reduce mint price every block", async function () {
      const initialPrice = await oldeus.getPrice(1);
      await moveBlocks(200);
      const modifiedPrice = await oldeus.getPrice(1);

      expect(initialPrice).to.above(modifiedPrice);
    });
    it("price should not be below min price", async () => {
      await moveBlocks(13000);
      let price = await oldeus.getPrice(0);
      price = price.toString();

      assert(
        price === ethers.utils.parseEther("0.04").toString(),
        "price greater or equal than target"
      );
    });
  });

  describe("minting process", () => {
    it("sould create random number between 1 and 3", async () => {
      let rand = await oldeus.getRandomNumber();
      rand = Number(rand.toString());
      assert(rand >= 0 && rand < 3);
    });

    it("whitelist mint", async () => {
      const merkleProof = tree.getHexProof(keccak256(owner.address));

      await oldeus.whitelistBuySeed(0, merkleProof);
      const balanceOfOwner = await oldeus.balanceOf(owner.address, 0);
      assert(balanceOfOwner.toString() === "1");
    });

    it("should mint a token", async () => {
      await oldeus.flipWhitelistPhase();
      await oldeus.buySeed(0, {
        value: ethers.utils.parseEther("0.1"),
      });
      const balanceOfMinter = await oldeus.balanceOf(owner.address, 0);
      assert(balanceOfMinter.toString() === "1");
    });
  });
});
