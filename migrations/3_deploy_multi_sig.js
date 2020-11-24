const BigNumber = require('bignumber.js');
const MultisigWalletWithDailyLimit = artifacts.require('MultiSigWalletWithDailyLimit.sol')
const MultisigWalletWithoutDailyLimit = artifacts.require('MultiSigWallet.sol')

module.exports = deployer => {
  deployer.deploy(MultisigWalletWithoutDailyLimit, ['0x7532C59C69828D4e756832BaE27b79FB28145C44','0x6cbC27065eE6CEcFEaf508588eFbd29Fc183fd34'], 2);
  console.log("Wallet deployed");
}
