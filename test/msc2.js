//const { singletons, BN, expectEvent } = require('@openzeppelin/test-helpers');

const MSC = artifacts.require("MSC2");
const MIS = artifacts.require("MToken");

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

contract("MSC Test", async accounts => {
        it("initial setup, fund distribution", async() => {
            let token = await MIS.deployed();
            let m = await MSC.deployed();
            await token.addMinter(accounts[0]);
            await token.mint(accounts[0], 100000);
            assert.equal(await token.balanceOf.call(accounts[0]), 100000, "account 2 should have 100000 balance");
        });

        it("call commit directly. ", async() => {
                let msc = await MSC.deployed();
                let token = await MIS.deployed();
                let initialBalance = await token.balanceOf.call(msc.address);
                assert.equal(initialBalance, 0);
                
                await token.approve(msc.address, 5000, {from : accounts[0]});
                await msc.commit(5000, {from: accounts[0]});

                let balance = await token.balanceOf.call(msc.address)
                assert.equal(balance, 5000);

                let {value, status} = await msc.parties(accounts[0]);
                assert.equal(value, 5000, "Account 0 should have pledged 5000");
                assert.equal(status, 0, "Account 0 should still in pending");
                let contractStatus = await msc.contractStatus();
                assert.equal(contractStatus, 0, "Contract should still be pending");
        });


});
