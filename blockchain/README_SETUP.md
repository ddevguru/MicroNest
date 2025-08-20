# Blockchain Setup Guide for MicroNest

## Overview
This guide will help you set up the blockchain functionality for MicroNest. The system uses Ethereum (Sepolia testnet) for group management and transactions.

## Prerequisites
1. **Node.js** (v16 or higher)
2. **npm** or **yarn**
3. **MetaMask** wallet extension
4. **Sepolia testnet ETH** (for gas fees)

## Step 1: Get Infura Project ID

1. Go to [Infura.io](https://infura.io/)
2. Create a free account
3. Create a new project
4. Go to Settings → Keys
5. Copy your **Project ID**

## Step 2: Deploy Smart Contract

### Option A: Using Remix (Easiest)

1. Go to [Remix IDE](https://remix.ethereum.org/)
2. Create a new file called `SavingsGroup.sol`
3. Copy the contract code from `contracts/SavingsGroup.sol`
4. Compile the contract (Solidity Compiler plugin)
5. Deploy to Sepolia testnet:
   - Select "Injected Provider - MetaMask"
   - Connect your MetaMask wallet
   - Switch to Sepolia testnet
   - Deploy with constructor parameters:
     - Name: "MicroNest Savings Group"
     - Description: "Decentralized savings group management"
     - Contribution Amount: 1000000000000000000 (1 ETH in wei)
     - Max Members: 20
     - Interest Rate: 500 (5% = 500 basis points)
6. Copy the deployed contract address

### Option B: Using Truffle (Advanced)

1. Install Truffle: `npm install -g truffle`
2. Navigate to the blockchain folder: `cd blockchain`
3. Install dependencies: `npm install`
4. Configure `truffle-config.js` with your Infura project ID
5. Deploy: `truffle migrate --network sepolia`

## Step 3: Update Configuration

1. Open `lib/services/blockchain_service.dart`
2. Update these constants:

```dart
class BlockchainService {
  // Replace YOUR_INFURA_PROJECT_ID with your actual project ID
  static const String _infuraUrl = 'https://sepolia.infura.io/v3/YOUR_ACTUAL_PROJECT_ID';
  
  // Replace with your deployed contract address
  static const String _contractAddress = '0xYOUR_ACTUAL_CONTRACT_ADDRESS';
}
```

## Step 4: Get Test ETH

1. Add Sepolia testnet to MetaMask:
   - Network Name: Sepolia
   - RPC URL: https://sepolia.infura.io/v3/YOUR_PROJECT_ID
   - Chain ID: 11155111
   - Currency Symbol: ETH
   - Block Explorer: https://sepolia.etherscan.io

2. Get free test ETH from faucets:
   - [Sepolia Faucet](https://sepoliafaucet.com/)
   - [Infura Sepolia Faucet](https://www.infura.io/faucet/sepolia)

## Step 5: Test Blockchain Integration

1. Run the app
2. Try to create or join a group
3. Check the console for blockchain status
4. Verify transactions on [Sepolia Etherscan](https://sepolia.etherscan.io/)

## Troubleshooting

### Common Issues:

1. **"Invalid argument (address)" Error**
   - Make sure you've updated the contract address
   - Verify the address is 40 characters long (without 0x prefix)

2. **"Blockchain not configured" Error**
   - Check that you've updated both Infura URL and contract address
   - Ensure the contract address is not the placeholder value

3. **Transaction Fails**
   - Check you have enough Sepolia ETH for gas
   - Verify you're connected to Sepolia testnet
   - Check MetaMask transaction details

4. **Contract Not Found**
   - Verify the contract was deployed successfully
   - Check the contract address is correct
   - Ensure you're on the right network

### Debug Steps:

1. Check console logs for blockchain initialization
2. Verify Infura project is active
3. Test contract interaction in Remix
4. Check MetaMask network settings

## Security Notes

⚠️ **IMPORTANT**: Never commit real private keys or mainnet addresses to version control!

- Use only testnet for development
- Keep private keys secure
- Use environment variables for production
- Regularly rotate API keys

## Next Steps

Once blockchain is working:
1. Test all group operations
2. Verify transaction history
3. Test smart contract functions
4. Consider upgrading to mainnet (requires real ETH)

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Verify all configuration steps
3. Check Infura project status
4. Review MetaMask settings
5. Check Sepolia network status

## Alternative Networks

You can also deploy to other testnets:
- **Goerli**: More stable, longer block time
- **Mumbai**: Polygon testnet, lower gas fees
- **BSC Testnet**: Binance Smart Chain testnet

Just update the network configuration in the blockchain service accordingly. 