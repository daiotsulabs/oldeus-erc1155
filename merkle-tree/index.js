//@param addresses array of addresses to be whitelisted
const { MerkleTree } = require("merkletreejs");
const { ethers } = require("ethers");
const { keccak256 } = ethers.utils;

/**
 * addresses = [{account, type: 1 | 2}] -> type 1 = wl 1 - type 2 = wl 2
 */

const generateMerkleTree = (addresses) => {
  const leaves = addresses.map((account) =>
    ethers.utils.solidityKeccak256(
      ["address", "uint256"],
      [account.address, account.type]
    )
  );

  const tree = new MerkleTree(leaves, keccak256, { sort: true });

  return tree;
};

const testMerkle = () => {
  const leaves = [
    { address: "0x22", type: 2 },
    { address: "0x33", type: 1 },
  ].map((x) =>
    ethers.utils.solidityKeccak256(["address", "uint256"], [x.address, x.type])
  );

  const tree = new MerkleTree(leaves, keccak256, { sort: true });

  const root = tree.getHexRoot();

  const leaf = keccak256("0x22", 2);
  const proof = tree.getHexProof(leaf);
  console.log(tree.verify(proof, leaf, root));
};

testMerkle();

module.exports = generateMerkleTree;
