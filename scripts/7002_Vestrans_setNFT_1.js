const { ethers, network } = require("hardhat");
const path = require('path');
const saveTransactionGasUsed = require("../utils/saveTransactionGasUsed");
const adresses = require("./0000_addresses.json")
const { DATA } = require("../utils/opt");
const { numToParse } = require("../utils/funcs");


const opt = {
  contractName:   DATA.Vestrans.contractName,
  tierName:       DATA.Vestrans.T1.name,
  maxSupply:      DATA.Vestrans.T1.maxSupply,
  price:          numToParse(DATA.Vestrans.T1.price),
  point:          DATA.Vestrans.T1.point,
  maxAllocation:  DATA.Vestrans.T1.maxAllocation
}

  console.log(opt);

async function main() {

  const contractABI = require('../artifacts/contracts/' + opt.contractName + ".sol/" + opt.contractName + ".json");

  
  const Contract = await ethers.getContractAt(contractABI.abi, adresses[network.name][opt.contractName]);

  
  try {
    const tx = await Contract.setNFTDetails(
      opt.tierName,
      opt.maxSupply,
      opt.price,
      opt.point,
      opt.maxAllocation
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
