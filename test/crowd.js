//const { singletons, BN, expectEvent } = require('@openzeppelin/test-helpers');

const MIS = artifacts.require("MToken");
const MULTI = artifacts.require("MultiSigMinter");
const Web3 = require("web3");
const web3 = new Web3();
const BN = require('bignumber.js');
total=new BN("100e18");


const PREFIX = "Returned error: VM Exception while processing transaction: ";

async function tryCatch(promise, message) {
            try {
                            await promise;
                            throw null;
                        }
            catch (error) {
                            assert(error, "Expected an error but did not get one");
                            assert(error.message.startsWith(PREFIX + message), "Expected an error starting with '" + PREFIX + message + "' but got '" + error.message + "' instead");
                        }
};

catchRevert = async function(promise) {await tryCatch(promise, "revert")};

contract("MToken Test", async accounts => {
        it("create accounts", async() => {
            
                let token = await MIS.deployed();
                await token.addMinter(accounts[0]);

                total = 2000;
                tamount = 0;
                let rnlist = []
                
                for (i = 0; i < total; ++i) {
                    rn = Math.random();
                    tamount += rn;
                    rnlist.push(rn);
                }
                for (i = 0; i < total; ++i) {
                    account = web3.eth.accounts.create();
                    console.log(account.address, account.privateKey);
                }
                
        });
});
