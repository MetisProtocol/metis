const MIS = artifacts.require("MToken");
//const METIS = artifacts.require("MetisToken");
require('@openzeppelin/test-helpers/configure')({ provider: web3.currentProvider, environment: 'truffle' });

const { singletons } = require('@openzeppelin/test-helpers');
const BN = require('bignumber.js');

module.exports = async function(deployer, network, accounts) {
      await deployer.deploy(MIS, [accounts[0]], new BN("10000000e18"));
  }
};
