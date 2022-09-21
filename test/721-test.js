const { inputToConfig } = require("@ethereum-waffle/compiler");
const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const generateMerkleTree = require("../merkle-tree");

describe("ERC721 Oldeus", function () {
  let seedsContract, mainContract;
  let owner, add1, add2;
  let tree, mkRoot;

  beforeEach(async function () {
    [owner, add1, add2] = await ethers.getSigners();

    tree = generateMerkleTree([
      { address: owner.address, type: 1 },
      { address: add1.address, type: 2 },
    ]);

    mkRoot = tree.getHexRoot();

    const contract = await ethers.getContractFactory("Seeds1155");
    seedsContract = await contract.deploy(
      "name",
      "symbol",
      "uri",
      mkRoot,
      owner.address
    );
    const mainContractf = await ethers.getContractFactory("Oldeus");
    mainContract = await mainContractf.deploy(
      "name",
      "symbol",
      seedsContract.address
    );
    seedsContract._setOldeus721Address(mainContract.address);
  });

  describe("Deployment", function () {
    it("shoud set correct constructor params", async () => {
      expect(await seedsContract.OLDEUS_721()).to.be.equal(
        mainContract.address
      );
      expect(await mainContract.SeedsContract()).to.be.equal(
        seedsContract.address
      );
    });
  });

  describe("721 mint functionality", function () {
    it("shoud burn a seed and mint an nft with tokenId 1", async () => {
      await seedsContract.changePhase(2);
      const minttx = await seedsContract.buySeed(3, {
        value: ethers.utils.parseEther("2"),
      });
      await minttx.wait();

      const balOfseeds = {
        0: await seedsContract.balanceOf(owner.address, 0),
        1: await seedsContract.balanceOf(owner.address, 1),
        2: await seedsContract.balanceOf(owner.address, 2),
      };

      await seedsContract.setApprovalForAll(mainContract.address, true);

      const uwu = Object.keys(balOfseeds)
        .map((key) => {
          const balance = parseInt(balOfseeds[key]);
          console.log(balance);
          if (balance !== 0) return key;
        })
        .filter((item) => item !== undefined);

      await mainContract.redeemEstarian(uwu);

      console.log(await mainContract.balanceOf(owner.address));

      expect(await mainContract.balanceOf(owner.address)).to.be.equal(1);
    });

    it("shouldn't allow burn from outside the contract", async () => {
      await expect(
        seedsContract.burnSeed(owner.address, [0])
      ).to.be.revertedWith("invalid address");
    });
  });
});
