const MIS = artifacts.require("MetisToken");
const MSC = artifacts.require("MSC");
require('@openzeppelin/test-helpers/configure')({ provider: web3.currentProvider, environment: 'truffle' });

const { singletons } = require('@openzeppelin/test-helpers');
const BN = require('bignumber.js');

module.exports = async function(deployer, network, accounts) {
  if (network === 'development') {
      // In a test environment an ERC777 token requires deploying an ERC1820 registry
      await singletons.ERC1820Registry(accounts[0]);
  }
  const tokenbits = (new BN(10)).pow(18); 
  const amount = (new BN(10000)).multipliedBy(tokenbits); 

  await deployer.deploy(MIS, amount, [],[],[]);
  if (network === 'development') {
      const token = await MIS.deployed();
      await deployer.deploy(MSC, [accounts[1], accounts[2]], accounts[0], 1, token.address, 10000);
  }
};
