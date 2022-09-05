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
    tree = generateMerkleTree([
      { address: owner.address, type: 1 },
      { address: addr1.address, type: 2 },
      { address: addr2.address, type: 1 },
    ]);

    merkleRoot = tree.getHexRoot();

    contract = await ethers.getContractFactory("Seeds1155");

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
    it("sould create random number between 1 and 3", async () => {
      let rand = await oldeus.getRandomNumber();
      rand = Number(rand.toString());
      assert(rand >= 0 && rand < 3);
    });

    it("whitelist mint", async () => {
      const msgvalue = { value: ethers.utils.parseEther("0.2") };
      const merkleProof = tree.getHexProof(
        keccak256(
          ethers.utils.solidityPack(["address", "uint256"], [owner.address, 1])
        )
      );

      console.log(merkleProof);

      console.log(
        tree.verify(merkleProof, keccak256(owner.address, 1), merkleRoot),
        "oni chan"
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
      await oldeus.flipWhitelistPhase();
      await expect(
        oldeus.buySeed(1, {
          value: ethers.utils.parseEther("0.2"),
        })
      ).to.emit(oldeus, "sale");
    });

    it("mint all nfts", async () => {
      const value = { value: ethers.utils.parseUnits("0.2", "ether") };
      await oldeus.flipWhitelistPhase();

      let count = {
        0: 0,
        1: 0,
        2: 0,
      };
      for (let i = 0; i < 30; i++) {
        const tx = await oldeus.buySeed(1, value);
        const txn = await tx.wait();

        const key = parseInt(txn.logs[1].topics[2].toString(), 16);
        count[key] += 1;
      }
      console.log(count);
      await expect(oldeus.balanceOf(owner.address, 0).toString() === "10");
    });
  });
});
