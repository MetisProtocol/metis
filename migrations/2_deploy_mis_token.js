const MIS = artifacts.require("MetisToken");
const MSC = artifacts.require("MSC");
require('@openzeppelin/test-helpers/configure')({ provider: web3.currentProvider, environment: 'truffle' });

const { singletons } = require('@openzeppelin/test-helpers');

module.exports = async function(deployer, network, accounts) {
  if (network === 'development') {
      // In a test environment an ERC777 token requires deploying an ERC1820 registry
      await singletons.ERC1820Registry(accounts[0]);
  }
  await deployer.deploy(MIS, '1000000000000000', [],[],[]);
  const token = await MIS.deployed();
  await deployer.deploy(MSC, [accounts[1], accounts[2]], [accounts[0]], 1, token.address, 10);
};
