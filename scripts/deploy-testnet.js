const hre = require("hardhat");
const generateMerkleTree = require("../merkle-tree");

//

(async () => {
  //array of addresses to whitelist in testnet
  const tree = generateMerkleTree([
    "0x7eC7aF8CFF090c533dc23132286f33dD31d13E29",
  ]);

  const Oldeus = await hre.ethers.getContractFactory("Seeds1155");
  //name, symbol, uri, mkroot, address that will receive wihdraw
  const oldeus = await Oldeus.deploy(
    "name",
    "symbol",
    "uri",
    tree.getHexRoot(),
    "0x7eC7aF8CFF090c533dc23132286f33dD31d13E29"
  );

  await oldeus.deployed();

  console.log("Contract deployed to ", oldeus.address);
})()
  .then(() => process.exit(0))
  .catch((err) => {
    console.log(err);
    process.exit(1);
  });
