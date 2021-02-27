//const { singletons, BN, expectEvent } = require('@openzeppelin/test-helpers');

const MIS = artifacts.require("MToken");
const MULTI = artifacts.require("MultiSigMinter");
const VAULT = artifacts.require("TokenVault");

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
                let multi = await MULTI.deployed();
                let vault = await VAULT.deployed();
                let result = await multi.proposeMint(vault.address, 100000, { from: accounts[0]});

                let pos = result.logs[0].args.proposalNo;
                await catchRevert(multi.signMint(0, {from: accounts[2]}));

                assert.equal(await token.balanceOf.call(vault.address), 0, "Account 1 should still have 0 balance");
                await multi.signMint(pos, {from: accounts[0]});
                assert.equal(await token.balanceOf.call(vault.address), 0, "Account 1 should still have 0 balance");
                await multi.signMint(pos, {from: accounts[1]});
                assert.equal(await token.balanceOf.call(vault.address), 100000, "Vault should have 100000 balance");
        });
        it("security", async() => {
                let vault = await VAULT.deployed();
                await catchRevert(vault.addNew(accounts[2], 10, 0, {from: accounts[2]}));
                await catchRevert(vault.addNewPending(accounts[2], 10,{from: accounts[2]}));
                await catchRevert(vault.setDate(accounts[2], 0, 0, {from: accounts[2]}));
        });
        it("addNew", async() => {
                let token = await MIS.deployed();
                let vault = await VAULT.deployed();

                assert.equal(await token.balanceOf.call(accounts[2]), 0, "Account 1 should still have 0 balance");
                let date = (new Date()).getTime();
                let timestamp = Math.floor(date / 1000);
                await vault.addNew(accounts[2], 1000, timestamp);
                assert.equal(await vault.checkArrangement(0, {from:accounts[2]}), "Amount:1000 Available on TS " + timestamp + " ARRANGED");

                await vault.addNew(accounts[2], 1000, timestamp + 1);
                assert.equal(await vault.checkArrangement(0, {from:accounts[2]}), "Amount:1000 Available on TS " + timestamp + " ARRANGED");
                assert.equal(await vault.checkArrangement(1, {from:accounts[2]}), "Amount:1000 Available on TS " + (timestamp + 1) + " ARRANGED");

                await vault.addNew(accounts[2], 1000, timestamp + 10000);
                assert.equal(await vault.checkArrangement(2, {from:accounts[2]}), "Amount:1000 Available on TS " + (timestamp + 10000) + " ARRANGED");

                await vault.addNew(accounts[3], 1000, timestamp);
                assert.equal(await vault.checkArrangement(0, {from:accounts[3]}), "Amount:1000 Available on TS " + timestamp + " ARRANGED");
                await vault.addNewPending(accounts[3], 1000);
                assert.equal(await vault.checkArrangement(1, {from:accounts[3]}), "Amount:1000 Available on TS 0 LOCKED");
                await vault.setDate(accounts[3], 1, timestamp + 10000);
                assert.equal(await vault.checkArrangement(1, {from:accounts[3]}), "Amount:1000 Available on TS " + (timestamp + 10000) + " ARRANGED");

        });

        it("claim", async() => {
                let token = await MIS.deployed();
                let vault = await VAULT.deployed();

                assert.equal(await token.balanceOf.call(accounts[2]), 0, "Account 2 should still have 0 balance");
                assert.equal(await token.balanceOf.call(accounts[3]), 0, "Account 3 should still have 0 balance");

                await vault.claim({from: accounts[4]});
                assert.equal(await token.balanceOf.call(accounts[4]), 0, "Account 3 should still have 0 balance");

                await vault.claim({from: accounts[2]});
                assert.equal(await token.balanceOf.call(accounts[2]), 2000, "Accounts 2 should have 2000 balance");

                await vault.claim({from: accounts[3]});
                assert.equal(await token.balanceOf.call(accounts[3]), 1000, "Accounts 3 should have 1000 balance");

        });

        it("addNewPendings", async() => {
                let token = await MIS.deployed();
                let vault = await VAULT.deployed();

                assert.equal(await token.balanceOf.call(accounts[4]), 0, "Account 1 should still have 0 balance");
                let date = (new Date()).getTime();
                let timestamp = Math.floor(date / 1000);
                await vault.addNewPendings([accounts[4],accounts[4],accounts[5]], [1000,20,30]);

                assert.equal(await vault.checkArrangement(0, {from:accounts[4]}), "Amount:1000 Available on TS 0 LOCKED");
                assert.equal(await vault.checkArrangement(1, {from:accounts[4]}), "Amount:20 Available on TS 0 LOCKED");

                assert.equal(await vault.checkArrangement(0, {from:accounts[5]}), "Amount:30 Available on TS 0 LOCKED");

                await vault.addNewPendings([accounts[4],accounts[4],accounts[5]], [1000,20,30]);

                assert.equal(await vault.checkArrangement(2, {from:accounts[4]}), "Amount:1000 Available on TS 0 LOCKED");
                assert.equal(await vault.checkArrangement(3, {from:accounts[4]}), "Amount:20 Available on TS 0 LOCKED");
                assert.equal(await vault.checkArrangement(1, {from:accounts[5]}), "Amount:30 Available on TS 0 LOCKED");

                await vault.setDates([accounts[4], accounts[5], accounts[4]], [1, 1, 0], [timestamp, timestamp, timestamp]);
                assert.equal(await vault.checkArrangement(0, {from:accounts[4]}), "Amount:1000 Available on TS " + (timestamp) + " ARRANGED");
                assert.equal(await vault.checkArrangement(1, {from:accounts[4]}), "Amount:20 Available on TS " + (timestamp) + " ARRANGED");
                assert.equal(await vault.checkArrangement(2, {from:accounts[4]}), "Amount:1000 Available on TS 0 LOCKED");
                assert.equal(await vault.checkArrangement(3, {from:accounts[4]}), "Amount:20 Available on TS 0 LOCKED");
            
                assert.equal(await vault.checkArrangement(0, {from:accounts[5]}), "Amount:30 Available on TS 0 LOCKED");

                assert.equal(await vault.checkArrangement(1, {from:accounts[5]}), "Amount:30 Available on TS " + (timestamp) + " ARRANGED");

        });
});
