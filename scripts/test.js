// Contracts
const M = artifacts.require("MToken")
const MSC = artifacts.require("TaskList2")
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
        const msc = await MSC.at("0xA021Bad662cB51Ea42A77BcdA28feA92032fd57e");

        // Set up users
        const user1 = accounts[0];

        console.log(await token.balanceOf.call(accounts[0]));
    }
    catch(error) {
        console.log(error)
    }

    callback()
}

