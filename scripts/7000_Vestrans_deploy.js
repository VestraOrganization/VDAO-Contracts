const { ethers, network } = require("hardhat");
const saveContractAddress = require("../utils/saveContractAddress");
const path = require('path');
const saveTransactionGasUsed = require("../utils/saveTransactionGasUsed");
const { DATA } = require("../utils/opt")

const opt = {
  ownerAddress: DATA.deploy.ownerAddress,
  stakeAddress: DATA.deploy.stakeDaoAddress,
  contractName: DATA.Vestrans.contractName,
  uri:          DATA.Vestrans.uri,
  tokenName:    DATA.Vestrans.tokenName,
  tokenSymbol:  DATA.Vestrans.tokenSymbol,

}

async function main() {
  const CONTRACT = await ethers.getContractFactory(opt.contractName);
  const contract = await CONTRACT.deploy(
    opt.ownerAddress, opt.stakeAddress, opt.uri, opt.tokenName, opt.tokenSymbol);

  console.log("Deploy Verify Options: ### ", contract.target,
    opt.ownerAddress, opt.stakeAddress, opt.uri, opt.tokenName, opt.tokenSymbol, " ###"
  );


  const deploymentTransaction = await contract.deploymentTransaction();
  const receipt = await deploymentTransaction.wait();

  await contract.waitForDeployment()

  await saveContractAddress(opt.contractName, contract.target);
  await saveTransactionGasUsed(path.basename(__filename), receipt.gasUsed.toString())
}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
