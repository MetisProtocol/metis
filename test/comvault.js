//const { singletons, BN, expectEvent } = require('@openzeppelin/test-helpers');

const MIS = artifacts.require("MToken");
const MULTI = artifacts.require("MultiSigMinter");
const VAULT = artifacts.require("ComVault");

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

contract("Vault Test", async accounts => {
        it("mint", async() => {
                let token = await MIS.deployed();
                let vault = await VAULT.deployed();
                await token.addMinter(accounts[0]);
                await token.mint(vault.address, 100000);
                await token.mint(accounts[2], 100000);
                assert.equal(await token.balanceOf.call(vault.address), 100000, "Vault should have 100000 balance");
                assert.equal(await token.balanceOf.call(accounts[2]), 100000, "account 2 should have 100000 balance");
        });
        it("security", async() => {
                let vault = await VAULT.deployed();
                await catchRevert(vault.addNew(accounts[2], 10, 10, {from: accounts[2]}));
                await catchRevert(vault.addNewBatch([accounts[2]], [10], [10],{from: accounts[2]}));
                await catchRevert(vault.setTge(0,{from: accounts[2]}));
                await catchRevert(vault.withdrawFund(accounts[0],{from: accounts[2]}));
                
        });
        it("addNew", async() => {
                let token = await MIS.deployed();
                let vault = await VAULT.deployed();

                await vault.addNew(accounts[2], 100000, 100000);
                let a = await vault.arrangements_.call(accounts[2], {from:accounts[2]});
                assert.equal(a.targetAmount, 100000);
                assert.equal(a.amount, 0);
                assert.equal(a.aStatus, 1);
                assert.equal(a.metisAmount, 100000);
                assert.equal(a.metisPaid, 0);
        });

        it("fund", async() => {
                let token = await MIS.deployed();
                let vault = await VAULT.deployed();

                assert.equal(await token.balanceOf.call(accounts[2]), 100000, "Account 1 should still have 0 balance");
                await token.approve(vault.address, 100000, {from:accounts[2]});
                await vault.fund(accounts[2], 100000, {from:accounts[2]});
                assert.equal(await token.balanceOf.call(accounts[2]), 0, "Account 2 should still have 0 balance");

                let a = await vault.arrangements_.call(accounts[2], {from:accounts[2]});
                assert.equal(a.targetAmount, 100000);
                assert.equal(a.amount, 100000);
                assert.equal(a.aStatus, 2);
                assert.equal(a.metisAmount, 100000);
                assert.equal(a.metisPaid, 0);
        });

        it("claim", async() => {
                let token = await MIS.deployed();
                let vault = await VAULT.deployed();

                let date = (new Date()).getTime();
                let timestamp = Math.floor(date / 1000);
                await vault.setTge(timestamp);

                assert.equal(await token.balanceOf.call(accounts[2]), 0, "Account 2 should still have 0 balance");

                await vault.claim({from: accounts[2]});
                assert.equal(await token.balanceOf.call(accounts[2]), 8333, "Account 2 should have 8333 balance");

                await catchRevert(vault.claim({from: accounts[3]}));
        });

});
