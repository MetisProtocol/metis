// Contracts
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

        for (i = 0; i < 50; i++) {
           const account = await web3.eth.accounts.create();
           console.log(account.address + "," + account.privateKey);
	}
    }
    catch(error) {
        console.log(error)
    }

    callback()
}

