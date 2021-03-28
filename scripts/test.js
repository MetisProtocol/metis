// Contracts
const M = artifacts.require("MToken")
const MSC = artifacts.require("MSC2")
//
// Utils
const ether = (n) => {
   return new web3.utils.BN(
       web3.utils.toWei(n.toString(), 'ether')
   )
}

module.exports = async function(callback) {
    try {
        // Fetch accounts from wallet - these are unlocked
        const accounts = await web3.eth.getAccounts()

        // Fetch the deployed exchange
        const token = await M.deployed();
        const msc = await MSC.deployed();

        // Set up users
        const user1 = accounts[0];

        console.log(await token.balanceOf.call(accounts[0]));
        console.log(await msc.contractStatus.call());
    }
    catch(error) {
        console.log(error)
    }

    callback()
}

