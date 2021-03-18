// Contracts
const Vault = artifacts.require("TokenVault")
const fs = require('fs');
const line= fs.readFileSync("investors").toString().trim();
console.log(line);
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
        const vault = await Vault.deployed()

        let date = (new Date()).getTime();
        let timestamp = Math.floor(date / 1000);
        await vault.addNew("0x0C1bfB3090350863BCE59d5c838D82668B3D7892", 1000, timestamp);

        // Set up users
        const user1 = accounts[0]
        console.log(await vault.checkArrangements({from:"0x0C1bfB3090350863BCE59d5c838D82668B3D7892"}));

    }
    catch(error) {
        console.log(error)
    }

    callback()
}

