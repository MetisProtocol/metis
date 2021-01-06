const fs = require('fs');
const csv = require('csv-parser');
const MIS = artifacts.require("MToken");
const MULTI = artifacts.require("MultiSigMinter");
const CROWD = artifacts.require("Crowd");
require('@openzeppelin/test-helpers/configure')({ provider: web3.currentProvider, environment: 'truffle' });

const { singletons } = require('@openzeppelin/test-helpers');

const BN = require('bignumber.js');
total=new BN("100e18");

module.exports = async function(deployer, network, accounts) {
        const token = await MIS.deployed();
        await deployer.deploy(CROWD,token.address);
        if (network === 'development') {
           let multi = await MULTI.deployed();
           let crowd = await CROWD.deployed();
           let result = await multi.proposeMint(crowd.address, total, { from: accounts[0]});
           let pos = result.logs[0].args.proposalNo;
           await multi.signMint(pos, {from: accounts[0]});
           await multi.signMint(pos, {from: accounts[1]});
        }
};
