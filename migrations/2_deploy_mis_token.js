const MIS = artifacts.require("MToken");
//const METIS = artifacts.require("MetisToken");
const MSC = artifacts.require("MSC");
require('@openzeppelin/test-helpers/configure')({ provider: web3.currentProvider, environment: 'truffle' });

const { singletons } = require('@openzeppelin/test-helpers');
const BN = require('bignumber.js');

module.exports = async function(deployer, network, accounts) {
  if (network === 'development') {
      // In a test environment an ERC777 token requires deploying an ERC1820 registry
      await singletons.ERC1820Registry(accounts[0]);
  }

  if (network === 'development') {
      await deployer.deploy(MIS, [accounts[0], accounts[1]]);
      const token = await MIS.deployed();
      //const token2 = await METIS.deployed(0, [accounts[0], accounts[1]], [accounts[0], accounts[1]],[accounts[0]]);
      //await deployer.deploy(MSC, [accounts[1], accounts[2]], accounts[0], 1, token.address, 10000);
  } else {
//      await singletons.ERC1820Registry(accounts[0]);
      await deployer.deploy(MIS, ['0x7532C59C69828D4e756832BaE27b79FB28145C44']);
      //await deployer.deploy(METIS, 0, [accounts[0], accounts[1]], [accounts[0], accounts[1]],[accounts[0]]);
  }
};
