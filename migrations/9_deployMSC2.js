const fs = require('fs');
const csv = require('csv-parser');
const C = artifacts.require("MSC2");
const MT = artifacts.require("MToken");
require('@openzeppelin/test-helpers/configure')({ provider: web3.currentProvider, environment: 'truffle' });

const { singletons } = require('@openzeppelin/test-helpers');

const BN = require('bignumber.js');

module.exports = async function(deployer, network, accounts) {
    await deployer.deploy(C, [accounts[0], "0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e"], accounts[0], 10, MT.address, 100);
};
