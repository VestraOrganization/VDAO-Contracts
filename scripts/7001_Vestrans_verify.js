const { ethers, run } = require("hardhat");
const adresses = require("./0000_addresses.json")
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
  if (network.name == "localhost") {
    console.log("You can't verify on Localhost. Network: " + network.name);
    return false;
  }

  console.log("Contract is verifying on Etherscan...");
  try {
    await run("verify:verify", {
      address: adresses[network.name][opt.contractName],
      constructorArguments: [
        opt.ownerAddress, opt.stakeAddress, opt.uri, opt.tokenName, opt.tokenSymbol,
      ],
    });
    console.log("Contract is verified.");
  } catch (error) {
    if (error.message.toLowerCase().includes("already verified")) {
      console.log("Contract has been verified already.");
    } else {
      throw error;
    }
  }

}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});


