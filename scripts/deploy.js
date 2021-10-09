// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const XeldoradoFactory = await hre.ethers.getContractFactory("XeldoradoFactory");
  const xeldoradoFactory = await XeldoradoFactory.deploy("0x58B1AE79E72aA23784e97934b80b750Bb7972d2a", "0xc778417E063141139Fce010982780140Aa0cD5Ab");

  await xeldoradoFactory.deployed();

  console.log("XeldoradoFactory deployed to:", xeldoradoFactory.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
