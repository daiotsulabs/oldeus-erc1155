//@param addresses array of addresses to be whitelisted
const { MerkleTree } = require("merkletreejs");
const { ethers } = require("ethers");
const { keccak256 } = ethers.utils;

const generateMerkleTree = (addresses) => {
  const leaves = addresses.map((account) => keccak256(account.address));
  const tree = new MerkleTree(leaves, keccak256, { sort: true });

  return tree;
};

module.exports = generateMerkleTree;
