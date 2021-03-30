const fs = require('fs');
const csv = require('csv-parser');
const C = artifacts.require("MSC2");
const MT = artifacts.require("MToken");
require('@openzeppelin/test-helpers/configure')({ provider: web3.currentProvider, environment: 'truffle' });

const { singletons } = require('@openzeppelin/test-helpers');

const BN = require('bignumber.js');

module.exports = async function(deployer, network, accounts) {
    await deployer.deploy(C, ["0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e"], "0x6cbC27065eE6CEcFEaf508588eFbd29Fc183fd34", 10, MT.address, 100);
};
