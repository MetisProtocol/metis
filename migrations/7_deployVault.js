const fs = require('fs');
const csv = require('csv-parser');
const V = artifacts.require("TokenVault");
const MT = artifacts.require("MToken");
require('@openzeppelin/test-helpers/configure')({ provider: web3.currentProvider, environment: 'truffle' });

const { singletons } = require('@openzeppelin/test-helpers');

const BN = require('bignumber.js');

module.exports = async function(deployer, network, accounts) {
   await deployer.deploy(V, MT.address);
};
