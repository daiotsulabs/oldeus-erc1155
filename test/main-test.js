const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ERC1155-oldeus", function () {
  let contract;
  let hardhatContract;
  let owner;
  let addr1;
  let addr2;
  let addrs;

  const NAME = "test contract";
  const SYMBOL = "OLDEUS";
  const URI = "sampleuri";

  beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    contract = await ethers.getContractFactory("Seeds1155");

    hardhatContract = await contract.deploy(NAME, SYMBOL, URI, addr1.address);
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
      expect(await hardhatContract.owner()).to.equal(owner.address);
      expect(await hardhatContract.multisigWallet()).to.equal(addr1.address);
    });
  });

  describe("dutch auction", function () {
    it("Should reduce mint price every block", async function () {
      const initialPrice = await hardhatContract.getPrice(1);
      await ethers.provider.send("evm_mine", [1654279999]);
      const modifiedPrice = await hardhatContract.getPrice(1);

      expect(initialPrice).to.above(modifiedPrice);
    });
  });
});
