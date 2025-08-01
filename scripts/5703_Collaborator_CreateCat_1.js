const { ethers, network } = require("hardhat");
const path = require('path');
const saveTransactionGasUsed = require("../utils/saveTransactionGasUsed");
const adresses = require("./0000_addresses.json")
const { DATA } = require("../utils/opt")


const opt = {
  contractName: DATA.Collaborations.contractName,
  catId:      DATA.Collaborations.categories[1].id,
  name:       DATA.Collaborations.categories[1].name,
  pool:       DATA.Collaborations.categories[1].pool,
  maxReward:  DATA.Collaborations.categories[1].maxReward,
}

async function main() {

  const contractABI = require('../artifacts/contracts/' + opt.contractName + ".sol/" + opt.contractName + ".json");

  const Contract = await ethers.getContractAt(contractABI.abi, adresses[network.name][opt.contractName]);

  try {
    const tx = await Contract.createCategory(
      opt.catId,
      opt.name,
      opt.pool,
      opt.maxReward
    );

    const receipt = await tx.wait();
    console.log("Success tx:", receipt.hash);

    await saveTransactionGasUsed(path.basename(__filename), receipt.gasUsed.toString())
  } catch (error) {
    console.error("Error! Message:", error.message);
  }

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
