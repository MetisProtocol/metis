/**
 * Use this file to configure your truffle project. It's seeded with some
 * common settings for different networks and features like migrations,
 * compilation and testing. Uncomment the ones you need or modify
 * them to suit your project as necessary.
 *
 * More information about configuration can be found at:
 *
 * truffleframework.com/docs/advanced/configuration
 *
 * To deploy via Infura you'll need a wallet provider (like truffle-hdwallet-provider)
 * to sign your transactions before they're sent to a remote public node. Infura accounts
 * are available for free at: infura.io/register.
 *
 * You'll also need a mnemonic - the twelve word phrase the wallet uses to generate
 * public/private key pairs. If you're publishing your code to GitHub make sure you load this
 * phrase from a file you've .gitignored so it doesn't accidentally become public.
 *
 */

const Web3 = require("web3");
const web3 = new Web3();
const HDWalletProvider = require('truffle-hdwallet-provider');
const ProviderWrapper = require("@eth-optimism/ovm-truffle-provider-wrapper");
require('dotenv').config();
// Set this to the desired Execution Manager Address -- required for the transpiler
process.env.EXECUTION_MANAGER_ADDRESS = process.env.EXECUTION_MANAGER_ADDRESS || "0xA193E42526F1FEA8C99AF609dcEabf30C1c29fAA";
const infuraKey = process.env.INFURAKEY;
const web3url = process.env.WEB3URL;

const fs = require('fs');
const mnemonic = fs.readFileSync(".secret").toString().trim();

module.exports = {
  /**
   * Networks define how you connect to your ethereum client and let you set the
   * defaults web3 uses to send transactions. If you don't specify one truffle
   * will spin up a development blockchain for you on port 9545 when you
   * run `develop` or `test`. You can ask a truffle command to use a specific
   * network from the command line, e.g
   *
   * $ truffle test --network <network-name>
   */

  networks: {
            test: {
                           network_id: 108,
                           provider: function() {
                                               return ProviderWrapper.wrapProviderAndStartLocalNode(new HDWalletProvider(mnemonic, "http://127.0.0.1:8545/", 0, 10));
                                       },
                        gasPrice: 0,
                        gas: 9000000,
                        },
              live: {
                             network_id: 108,
                             provider: function () {
                                               return ProviderWrapper.wrapProvider(new HDWalletProvider(mnemonic, web3url, 0, 10));
                                            },
                             gasPrice: 0,
                             gas: 9000000,
                          },
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
        version: "./node_modules/@eth-optimism/solc-transpiler",
    }
  }
}
