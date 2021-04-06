const M = artifacts.require("MToken")
const T = artifacts.require("TokenVault")
const MINTER = artifacts.require("MultiSigMinter")

//require('@openzeppelin/test-helpers/configure')({ provider: web3.currentProvider, environment: 'truffle' });

//const { singletons } = require('@openzeppelin/test-helpers');

const BN = require('bignumber.js');

module.exports = async function(deployer, network, accounts) {
        // Fetch accounts from wallet - these are unlocked
        const accounts = await web3.eth.getAccounts()

        const newaddr = "0x886d5203cE6EDc8BA719ea5931E689606e84492B"
        // Fetch the deployed exchange
        const token = await M.deployed();
        const v = await T.deployed();
        const m = await MINTER.deployed();

        console.log(await token.transferOwnership(newaddr));
        console.log(await v.transferOwnership(newaddr));
        console.log(await m.transferOwnership(newaddr));
};
