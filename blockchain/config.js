// Blockchain Configuration for MicroNest
// Update these values with your actual blockchain setup

module.exports = {
  // Network Configuration
  networks: {
    sepolia: {
      name: 'Sepolia Testnet',
      rpcUrl: 'https://sepolia.infura.io/v3/YOUR_INFURA_PROJECT_ID',
      chainId: 11155111,
      blockExplorer: 'https://sepolia.etherscan.io',
      currency: 'ETH',
      gasPrice: '20', // in gwei
    },
    goerli: {
      name: 'Goerli Testnet',
      rpcUrl: 'https://goerli.infura.io/v3/YOUR_INFURA_PROJECT_ID',
      chainId: 5,
      blockExplorer: 'https://goerli.etherscan.io',
      currency: 'ETH',
      gasPrice: '15', // in gwei
    },
    mumbai: {
      name: 'Mumbai Testnet (Polygon)',
      rpcUrl: 'https://polygon-mumbai.infura.io/v3/YOUR_INFURA_PROJECT_ID',
      chainId: 80001,
      blockExplorer: 'https://mumbai.polygonscan.com',
      currency: 'MATIC',
      gasPrice: '30', // in gwei
    }
  },

  // Smart Contract Configuration
  contracts: {
    savingsGroup: {
      name: 'SavingsGroup',
      address: '0x0000000000000000000000000000000000000000', // Update with your deployed address
      abi: './contracts/SavingsGroup.json', // Path to compiled ABI
      gasLimit: 500000,
    }
  },

  // Wallet Configuration
  wallet: {
    defaultGasPrice: '20', // in gwei
    maxGasLimit: 1000000,
    confirmations: 3, // Number of block confirmations
  },

  // Infura Configuration
  infura: {
    projectId: 'YOUR_INFURA_PROJECT_ID', // Update with your project ID
    projectSecret: 'YOUR_INFURA_PROJECT_SECRET', // Optional, for private endpoints
  },

  // Development Configuration
  development: {
    useLocalNetwork: false, // Set to true to use local Ganache
    localRpcUrl: 'http://127.0.0.1:8545',
    localChainId: 1337,
    mnemonic: 'test test test test test test test test test test test junk', // Only for local testing
  }
};

// Instructions:
// 1. Replace 'YOUR_INFURA_PROJECT_ID' with your actual Infura project ID
// 2. Update the contract address with your deployed contract address
// 3. Choose the network you want to use (sepolia recommended for testing)
// 4. Update gas prices if needed for your chosen network 