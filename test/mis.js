//const { singletons, BN, expectEvent } = require('@openzeppelin/test-helpers');

const MIS = artifacts.require("MToken");
const MULTI = artifacts.require("MultiSigMinter");

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
        it("mint", async() => {
                let token = await MIS.deployed();
                let multi = await MULTI.deployed();
                await multi.addMinter(accounts[2]);
                let result = await multi.proposeMint(accounts[1], 100000, { from: accounts[0]});

                let pos = result.logs[0].args.proposalNo;
                assert.equal(await token.balanceOf.call(accounts[1]), 0, "Account 1 should still have 0 balance");
                await multi.signMint(pos, {from: accounts[0]});
                assert.equal(await token.balanceOf.call(accounts[1]), 0, "Account 1 should still have 0 balance");
                await multi.signMint(pos, {from: accounts[1]});
                assert.equal(await token.balanceOf.call(accounts[1]), 0, "Account 1 should still have 0 balance");
                await multi.signMint(pos, {from: accounts[2]});
                assert.equal(await token.balanceOf.call(accounts[1]), 100000, "Account 1 should still have 100000 balance");
        });
        it("mintbymetis", async() => {
                let token = await MIS.deployed();
                await token.addMinter(accounts[0]);

                assert.equal(await token.balanceOf.call(accounts[2]), 0, "Account 1 should still have 0 balance");
                await token.mint(accounts[2], 100000, {from: accounts[0]});
                assert.equal(await token.balanceOf.call(accounts[2]), 100000, "Account 1 should still have 100000 balance");
                await catchRevert(token.mint(accounts[2], 1000000, {from: accounts[0]}));
                await token.removeMinter(accounts[0]);
                await catchRevert(token.mint(accounts[2], 100000, {from: accounts[0]}));
        });

        it("mint2", async() => {
                let token = await MIS.deployed();
                let multi = await MULTI.deployed();
                await multi.removeMinter(accounts[2]);
                await catchRevert(multi.proposeMint(accounts[1], 100000, { from: accounts[2]}));
                await catchRevert(multi.signMint(0, {from: accounts[2]}));
        });

        it("burn", async() => {
                let token = await MIS.deployed();
                let multi = await MULTI.deployed();
                let result = await multi.proposeBurn(accounts[1], 100000, { from: accounts[0]});
                let pos = result.logs[0].args.proposalNo;
                assert.equal(await token.balanceOf.call(accounts[1]), 100000, "Account 1 should still have 100000 balance");
                await multi.signBurn(pos, {from: accounts[0]});
                assert.equal(await token.balanceOf.call(accounts[1]), 100000, "Account 1 should still have 100000 balance");
                await multi.signBurn(pos, {from: accounts[1]});
                assert.equal(await token.balanceOf.call(accounts[1]), 0, "Account 1 should still have 0 balance");
        });

        it("burn2", async() => {
                let token = await MIS.deployed();
                let multi = await MULTI.deployed();
                await catchRevert(multi.proposeBurn(accounts[1], 100000, { from: accounts[2]}));
                await catchRevert(multi.signBurn(0, {from: accounts[2]}));
        });


});
