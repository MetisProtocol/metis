const BigNumber = require('bignumber.js');
const MultisigWalletWithDailyLimit = artifacts.require('MultiSigWalletWithDailyLimit.sol')
const MultisigWalletWithoutDailyLimit = artifacts.require('MultiSigWallet.sol')

module.exports = async function(deployer, network, accounts) {
  if (network === 'development') {
      deployer.deploy(MultisigWalletWithoutDailyLimit, [accounts[0], accounts[1]], 2);
  } else {
      deployer.deploy(MultisigWalletWithoutDailyLimit, ['0xFA30D7D32288C2F27cD5a099dB7507B085b36071','0xAbe26fAeE77419897090bC4c5A112D463443a662'], 2);
  }
}
