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

  // first deploy $stake token
/*  const stakeToken = await hre.ethers.getContractFactory("Stake");
  const deployedStakeToken = await stakeToken.deploy();
  await deployedStakeToken.deployed();
  const $stake_address = deployedStakeToken.address; */

  //deploy Billboard contract 

  const BillboardContract = await hre.ethers.getContractFactory("BillboardContract");
  const deployedBillboardContract = await split.deploy(BillboardContract);
  await deployedBillboardContract.deployed();




 

 // console.log("$stakeToken deployed at:", $stake_address);
  console.log("billboard contract deployed at:", deployedBillboardContract.address );
}
//stakeToken deployed at: 0xFb353774Ace94C3Eaa9fD04E7D2C4c48537A4eDd
//split contract deployed at: 0xA9cddDB864482609124236955314AE11A3ada360
//both on rinkeby
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
