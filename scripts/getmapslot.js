// Contracts
const Vault = artifacts.require("TokenVault")
const fs = require('fs');
//
// Utils
const ether = (n) => {
   return new web3.utils.BN(
       web3.utils.toWei(n.toString(), 'ether')
   )
}

const standardizeInput = input =>
      web3.utils.toHex(input).replace('0x', '').padStart(64, '0')

const getMappingSlot = (mappingSlot, key) => {
      const mappingSlotPadded = standardizeInput(mappingSlot)
      const keyPadded = standardizeInput(key)
      const slot = web3.utils.sha3(keyPadded.concat(mappingSlotPadded), {
              encoding: 'hex'
            })

      return slot
}

const getMappingStorage = async (address, mappingSlot, key) => {
      const mappingKeySlot = getMappingSlot(mappingSlot.toString(), key)
      const complexStorage = await web3.eth.getStorageAt(address, mappingKeySlot)
      return complexStorage
}
module.exports = async function(callback) {
    try {
        // Fetch accounts from wallet - these are unlocked
        console.log(getMappingSlot(1, 'OVM_L1CrossDomainMessenger'));

    }
    catch(error) {
        console.log(error)
    }

    callback()
}

