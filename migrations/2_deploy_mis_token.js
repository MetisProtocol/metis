const MIS = artifacts.require("MToken");
//const METIS = artifacts.require("MetisToken");
const MULTI = artifacts.require("MultiSigMinter");
require('@openzeppelin/test-helpers/configure')({ provider: web3.currentProvider, environment: 'truffle' });

const { singletons } = require('@openzeppelin/test-helpers');
const BN = require('bignumber.js');

module.exports = async function(deployer, network, accounts) {
  if (network === 'development') {
      // In a test environment an ERC777 token requires deploying an ERC1820 registry
      await singletons.ERC1820Registry(accounts[0]);
  }

  if (network === 'development') {
      await deployer.deploy(MIS, []);
      const token = await MIS.deployed();
      //const token2 = await METIS.deployed(0, [accounts[0], accounts[1]], [accounts[0], accounts[1]],[accounts[0]]);
      await deployer.deploy(MULTI, [accounts[0], accounts[1]],token.address);
      const minter = await MULTI.deployed();
      token.addMinter(minter.address);
  } else {
      await deployer.deploy(MIS, []);
      const token = await MIS.deployed();
      await deployer.deploy(MULTI, [],token.address);
      const minter = await MULTI.deployed();
      token.addMinter(minter.address);
  }
};
