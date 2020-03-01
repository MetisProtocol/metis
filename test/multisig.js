//const { singletons, BN, expectEvent } = require('@openzeppelin/test-helpers');

const MIS = artifacts.require("MetisToken");
const MULTI = artifacts.require("MultiSig");

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

contract("MultiSig Test", async accounts => {
        it("mint", async() => {
                let token = await MIS.deployed();
                let multi = await MULTI.deployed();
                let result = await token.proposeMint(multi.address, 100000, { from: accounts[0]});
                let pos = result.logs[0].args.proposalNo;
                await token.signMint(pos, {from: accounts[0]});
                await token.signMint(pos, {from: accounts[1]});
                assert.equal(await token.balanceOf.call(multi.address), 100000, "Account should have 100000 balance");
        });

        it("propose", async() => {
                let token = await MIS.deployed();
                let multi = await MULTI.deployed();

                await multi.propose(accounts[1], 100000, web3.utils.toHex("test"), { from: accounts[0]});

                assert.equal(await token.balanceOf.call(multi.address), 100000, "contract account should still have 100000 balance");
                assert.equal(await token.balanceOf.call(accounts[1]), 0, "target account should still have 0 balance");

                await multi.propose(accounts[1], 100000, web3.utils.toHex("test"), { from: accounts[1]});
                assert.equal(await token.balanceOf.call(multi.address), 0, "contract account should have 0 balance");
                assert.equal(await token.balanceOf.call(accounts[1]), 100000, "Account should have 100000 balance");
        });


});
