const MIS = artifacts.require("MToken");
//const METIS = artifacts.require("MetisToken");
const MULTI = artifacts.require("MultiSigMinter");
require('@openzeppelin/test-helpers/configure')({ provider: web3.currentProvider, environment: 'truffle' });

const { singletons } = require('@openzeppelin/test-helpers');
const BN = require('bignumber.js');

module.exports = async function(deployer, network, accounts) {
  if (network === 'development') {
      // In a test environment an ERC777 token requires deploying an ERC1820 registry
      //await singletons.ERC1820Registry(accounts[0]);
  }

  if (network === 'development') {
      await deployer.deploy(MIS, [], new BN("500000e18"));
      const token = await MIS.deployed();
      //const token2 = await METIS.deployed(0, [accounts[0], accounts[1]], [accounts[0], accounts[1]],[accounts[0]]);
      await deployer.deploy(MULTI, [accounts[0], accounts[1]],token.address);
      const minter = await MULTI.deployed();
      await token.addMinter(minter.address);
  } else {
      await deployer.deploy(MIS, [], new BN("10000000e18"));
      //const token = await MIS.at('0x9E32b13ce7f2E80A01932B42553652E053D6ed8e');
      const token = await MIS.deployed();
      await deployer.deploy(MULTI, ['0xFA30D7D32288C2F27cD5a099dB7507B085b36071','0xAbe26fAeE77419897090bC4c5A112D463443a662'],token.address);
      const minter = await MULTI.deployed();
      await token.addMinter(minter.address);
  }
};
