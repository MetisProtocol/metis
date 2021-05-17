// Contracts
const Vault = artifacts.require("TokenVault")
//
// Utils
const ether = (n) => {
   return new web3.utils.BN(
       web3.utils.toWei(n.toString(), 'ether')
   )
}

module.exports = async function(callback) {
    try {

        // Fetch the deployed exchange
        const vault = await Vault.deployed()

        await vault.init1();
        await vault.init2();

    }
    catch(error) {
        console.log(error)
    }

    callback()
}

