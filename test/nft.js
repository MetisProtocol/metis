//const { singletons, BN, expectEvent } = require('@openzeppelin/test-helpers');

const NFT = artifacts.require("MetisNFT");

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

contract("MetisNFT Test", async accounts => {
        it("basic security", async() => {
           let token = await NFT.deployed();
           await catchRevert(token.addMinter(accounts[2], {from: accounts[1]}));
           await catchRevert(token.awardItem(accounts[1],0, "a", "md5", {from: accounts[1]}));
           await catchRevert(token.awardItem(accounts[1],0, "a", "md5", {from: accounts[1]}));
           await catchRevert(token.mintWithTokenURI(accounts[1], "1", "a", {from: accounts[1]}));
           await catchRevert(token.burn("0", {from: accounts[1]}));
           await catchRevert(token.pause({from: accounts[1]}));
           await catchRevert(token.addMinter(accounts[1], {from: accounts[1]}));
           await catchRevert(token.setBaseURI("base", {from: accounts[1]}));
           
        });
        it("mint", async() => {
            let token = await NFT.deployed();
            await token.addMinter(accounts[2]);
            await token.setBaseURI("base/", {from: accounts[2]});
            let result = await token.awardItem(accounts[1], 0, "uri", "md5", {from: accounts[2]});
            let id = result.logs[0].args.tokenId; 
            assert.equal(await token.ownerOf.call(id), accounts[1], "Account 1 should still have the token");
            assert.equal(await token.quality(id), 0, "token should have quality 0");
            assert.equal(await token.md5(id),"md5", "token md5 mismatch");
            assert.equal(await token.tokenURI(id),"base/uri", "token uri mismatch");
        });

});
