//const { singletons, BN, expectEvent } = require('@openzeppelin/test-helpers');

const MSC = artifacts.require("MSC");
const MIS = artifacts.require("MetisToken");

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
                let msc = await MSC.deployed();
                let token = await MIS.deployed();
                await token.transfer(accounts[1], 100000, { from: accounts[0]});
                await token.transfer(accounts[2], 100000, { from: accounts[0]});
                let balance1 = await token.balanceOf.call(accounts[1]);
                assert.equal(balance1.valueOf(), 100000);
                let balance2 = await token.balanceOf.call(accounts[2]);
                assert.equal(balance2.valueOf(), 100000);
        });

        it("send token should trigger commit", async() => {
                let msc = await MSC.deployed();
                let token = await MIS.deployed();
                let initialBalance = await token.balanceOf.call(msc.address);
                assert.equal(initialBalance, 0);

                await token.transfer(msc.address, 10000, { from: accounts[1]});
                let balance = await token.balanceOf.call(msc.address)
                assert.equal(balance, 10000);

                let {value, status} = await msc.parties(accounts[1]);
                assert.equal(value, 10000, "Account 1 should have pledged 10000");
                assert.equal(status, 1, "Account 1 should have committed");
                let contractStatus = await msc.contractStatus();
                assert.equal(contractStatus, 0, "Contract should still be pending");
        });

        it("call commit directly. require authorize operator call first", async() => {
                let msc = await MSC.deployed();
                let token = await MIS.deployed();
                let initialBalance = await token.balanceOf.call(msc.address);
                assert.equal(initialBalance, 10000);
                
                await token.authorizeOperator(msc.address, {from : accounts[2]});
                await msc.commit(5000, {from: accounts[2]});

                let balance = await token.balanceOf.call(msc.address)
                assert.equal(balance, 15000);

                let {value, status} = await msc.parties(accounts[2]);
                assert.equal(value, 5000, "Account 2 should have pledged 5000");
                assert.equal(status, 0, "Account 2 should still in pending");
                let contractStatus = await msc.contractStatus();
                assert.equal(contractStatus, 0, "Contract should still be pending");
        });

        it("account send more token to commit the contract", async() => {
                let msc = await MSC.deployed();
                let token = await MIS.deployed();
                let initialBalance = await token.balanceOf.call(msc.address);
                assert.equal(initialBalance, 15000);

                await token.transfer(msc.address, 10000, { from: accounts[2]});
                let balance = await token.balanceOf.call(msc.address)
                assert.equal(balance, 25000);

                let {value, status} = await msc.parties(accounts[2]);
                assert.equal(value, 15000, "Account 2 should have pledged 10000");
                assert.equal(status, 1, "Account 2 should have committed");
                let contractStatus = await msc.contractStatus();
                assert.equal(contractStatus, 1, "Contract should be effective");
        });

        it("transfer between participants", async() => {
                let msc = await MSC.deployed();
                let token = await MIS.deployed();
                let initialBalance = await token.balanceOf.call(msc.address);
                assert.equal(initialBalance, 25000);

                await msc.send(accounts[1], 5000, { from: accounts[2]});
                let balance = await token.balanceOf.call(msc.address)
                assert.equal(balance, 25000, "transfer should not change msc balance");
                assert.equal(await token.balanceOf.call(accounts[1]), 90000, "transfer should not affect the balance of account 1");
                assert.equal(await token.balanceOf.call(accounts[2]), 85000, "transfer should not affect the balance of account 2");

                let {value, status} = await msc.parties(accounts[2]);
                assert.equal(value, 10000, "Account 2 should have left 10000");
                let result = await msc.parties(accounts[1]);
                assert.equal(result.value, 15000, "Account 1 should have left 15000");

                let contractStatus = await msc.contractStatus();
                assert.equal(contractStatus, 1, "Contract should be effective");
        });

        it("try exit", async() => {
                let msc = await MSC.deployed();
                let token = await MIS.deployed();
                let initialBalance = await token.balanceOf.call(msc.address);
                assert.equal(initialBalance, 25000);

                await msc.iwantout({ from: accounts[1]});
                let balance = await token.balanceOf.call(msc.address)
                assert.equal(balance, 25000, "transfer should not change msc balance");
                assert.equal(await token.balanceOf.call(accounts[1]), 90000, "transfer should not affect the balance of account 1");
                assert.equal(await token.balanceOf.call(accounts[2]), 85000, "transfer should not affect the balance of account 2");

                let {value, status} = await msc.parties(accounts[1]);
                assert.equal(value, 15000, "Account 1 should have left 15000");
                assert.equal(status, 2, "Account 1 should have signaled exit");
                let result = await msc.parties(accounts[2]);
                assert.equal(result.value, 10000, "Account 2 should have left 10000");
                assert.equal(result.status, 1, "Account 2 should still be commited");

                let contractStatus = await msc.contractStatus();
                assert.equal(contractStatus, 1, "Contract should still be effective");

                // withdraw should not be possible
                await catchRevert(msc.withdraw({ from: accounts[1]}));

                await catchRevert(msc.withdraw({ from: accounts[2]}));
        });

        it("try dispute", async() => {
                let msc = await MSC.deployed();
                let token = await MIS.deployed();
                let initialBalance = await token.balanceOf.call(msc.address);
                assert.equal(initialBalance, 25000);

                await msc.dispute({ from: accounts[2]});
                let balance = await token.balanceOf.call(msc.address)
                assert.equal(balance, 25000, "transfer should not change msc balance");
                assert.equal(await token.balanceOf.call(accounts[1]), 90000, "transfer should not affect the balance of account 1");
                assert.equal(await token.balanceOf.call(accounts[2]), 85000, "transfer should not affect the balance of account 2");

                let {value, status} = await msc.parties(accounts[1]);
                assert.equal(value, 15000, "Account 1 should have left 15000");
                assert.equal(status, 2, "Account 1 should have signaled exit");
                let result = await msc.parties(accounts[2]);
                assert.equal(result.value, 10000, "Account 2 should have left 10000");
                assert.equal(result.status, 4, "Account 2 should signal dispute");

                let contractStatus = await msc.contractStatus();
                assert.equal(contractStatus, 3, "Contract should be dispute");

                // withdraw should not be possible
                await catchRevert(msc.withdraw({ from: accounts[1]}));

                await catchRevert(msc.withdraw({ from: accounts[2]}));
        });

        it("withdraw dispute", async() => {
                let msc = await MSC.deployed();
                let token = await MIS.deployed();
                let initialBalance = await token.balanceOf.call(msc.address);
                assert.equal(initialBalance, 25000);

                await msc.withdrawDispute({ from: accounts[2]});
                let balance = await token.balanceOf.call(msc.address)
                assert.equal(balance, 25000, "transfer should not change msc balance");
                assert.equal(await token.balanceOf.call(accounts[1]), 90000, "transfer should not affect the balance of account 1");
                assert.equal(await token.balanceOf.call(accounts[2]), 85000, "transfer should not affect the balance of account 2");

                let {value, status} = await msc.parties(accounts[1]);
                assert.equal(value, 15000, "Account 1 should have left 15000");
                assert.equal(status, 2, "Account 1 should have signaled exit");
                let result = await msc.parties(accounts[2]);
                assert.equal(result.value, 10000, "Account 2 should have left 10000");
                assert.equal(result.status, 1, "Account 2 should be committed");

                let contractStatus = await msc.contractStatus();
                assert.equal(contractStatus, 1, "Contract should be effective");

                // withdraw should not be possible
                await catchRevert(msc.withdraw({ from: accounts[1]}));

                await catchRevert(msc.withdraw({ from: accounts[2]}));
        });

        it("dispute again", async() => {
                let msc = await MSC.deployed();
                let token = await MIS.deployed();
                let initialBalance = await token.balanceOf.call(msc.address);
                assert.equal(initialBalance, 25000);

                await msc.dispute({ from: accounts[2]});
                let balance = await token.balanceOf.call(msc.address)
                assert.equal(balance, 25000, "transfer should not change msc balance");
                assert.equal(await token.balanceOf.call(accounts[1]), 90000, "transfer should not affect the balance of account 1");
                assert.equal(await token.balanceOf.call(accounts[2]), 85000, "transfer should not affect the balance of account 2");

                let {value, status} = await msc.parties(accounts[1]);
                assert.equal(value, 15000, "Account 1 should have left 15000");
                assert.equal(status, 2, "Account 1 should have signaled exit");
                let result = await msc.parties(accounts[2]);
                assert.equal(result.value, 10000, "Account 2 should have left 10000");
                assert.equal(result.status, 4, "Account 2 should be dispute");

                let contractStatus = await msc.contractStatus();
                assert.equal(contractStatus, 3, "Contract should be dispute");

                // withdraw should not be possible
                await catchRevert(msc.withdraw({ from: accounts[1]}));

                await catchRevert(msc.withdraw({ from: accounts[2]}));
        });

        it("dispute resolution", async() => {
                let msc = await MSC.deployed();
                let token = await MIS.deployed();
                let initialBalance = await token.balanceOf.call(msc.address);
                assert.equal(initialBalance, 25000);

                // participants cannot resolve dispute
                await catchRevert(msc.resolveDispute([accounts[1],accounts[2]], [10000,15000], { from: accounts[1]}));

                // facilitator cannot resolve if not requested 
                await catchRevert(msc.resolveDispute([accounts[1],accounts[2]], [10000,15000], { from: accounts[0]}));

                await msc.resolutionRequest({ from: accounts[1]});
                await msc.resolveDispute([accounts[1],accounts[2]], [10000,15000], { from: accounts[0]});

                let balance = await token.balanceOf.call(msc.address)
                assert.equal(balance, 25000, "resolution should not change msc balance");
                assert.equal(await token.balanceOf.call(accounts[1]), 90000, "transfer should not affect the balance of account 1");
                assert.equal(await token.balanceOf.call(accounts[2]), 85000, "transfer should not affect the balance of account 2");

                let {value, status} = await msc.parties(accounts[1]);
                assert.equal(value, 10000, "Account 1 should have left 10000");
                assert.equal(status, 3, "Account 1 should be completed");
                let result = await msc.parties(accounts[2]);
                assert.equal(result.value, 15000, "Account 2 should have left 15000");
                assert.equal(result.status, 3, "Account 2 should be completed");

                let contractStatus = await msc.contractStatus();
                assert.equal(contractStatus, 2, "Contract should be completed");
        });

        it("withdraw and exit", async() => {
                let msc = await MSC.deployed();
                let token = await MIS.deployed();
                let initialBalance = await token.balanceOf.call(msc.address);
                assert.equal(initialBalance, 25000);

                // participants cannot do these things anymore
                await catchRevert(msc.dispute({ from: accounts[1]}));
                await catchRevert(msc.iwantout({ from: accounts[1]}));
                await catchRevert(msc.resolutionRequest({ from: accounts[1]}));
                // facilitator cannot resolve anymore
                await catchRevert(msc.resolveDispute([accounts[1],accounts[2]], [10000,15000], { from: accounts[0]}));

                await msc.withdraw({from: accounts[1]});
                let balance = await token.balanceOf.call(msc.address)
                assert.equal(balance, 15000, "resolution should have 15000 left");
                assert.equal(await token.balanceOf.call(accounts[1]), 100000, "withdraw should restore the balance to 100000 for account 1");
                assert.equal(await token.balanceOf.call(accounts[2]), 85000, "transfer should not affect the balance of account 2");

                await msc.withdraw({from: accounts[2]});
                balance = await token.balanceOf.call(msc.address)
                assert.equal(balance, 0, "resolution should have 0 left");
                assert.equal(await token.balanceOf.call(accounts[1]), 100000, "withdraw should restore the balance to 100000 for account 1");
                assert.equal(await token.balanceOf.call(accounts[2]), 100000, "withdraw should restore the balance to 100000 for account 2");

                assert.equal(await web3.eth.getCode(msc.address), "0x", "Contract should be destroyed");
        });

});
