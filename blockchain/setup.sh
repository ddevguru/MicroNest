#!/bin/bash

echo "🚀 MicroNest Blockchain Setup Script"
echo "====================================="
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js first."
    echo "   Download from: https://nodejs.org/"
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed. Please install npm first."
    exit 1
fi

echo "✅ Node.js and npm are installed"
echo ""

# Install dependencies
echo "📦 Installing dependencies..."
npm install
echo ""

# Check if config.js exists
if [ ! -f "config.js" ]; then
    echo "❌ config.js not found. Please run this script from the blockchain directory."
    exit 1
fi

echo "🔧 Configuration Setup"
echo "======================"
echo ""

# Check if Infura project ID is set
if grep -q "YOUR_INFURA_PROJECT_ID" config.js; then
    echo "⚠️  Infura Project ID not configured"
    echo "   Please update config.js with your Infura project ID"
    echo "   Get it from: https://infura.io/"
    echo ""
fi

# Check if contract address is set
if grep -q "0x0000000000000000000000000000000000000000" config.js; then
    echo "⚠️  Contract address not configured"
    echo "   Please deploy the contract first or update the address in config.js"
    echo ""
fi

echo "📋 Setup Instructions:"
echo "======================"
echo ""
echo "1. Get Infura Project ID:"
echo "   - Go to https://infura.io/"
echo "   - Create account and project"
echo "   - Copy Project ID from Settings → Keys"
echo "   - Update config.js"
echo ""
echo "2. Deploy Smart Contract:"
echo "   - Option A: Use Remix IDE (easiest)"
echo "   - Option B: Use this script with Hardhat"
echo ""
echo "3. Update Contract Address:"
echo "   - Copy deployed contract address"
echo "   - Update config.js"
echo ""
echo "4. Test Blockchain Integration:"
echo "   - Run the Flutter app"
echo "   - Try creating/joining groups"
echo ""

echo "🔗 Useful Links:"
echo "================="
echo "• Infura: https://infura.io/"
echo "• Remix IDE: https://remix.ethereum.org/"
echo "• Sepolia Faucet: https://sepoliafaucet.com/"
echo "• Sepolia Etherscan: https://sepolia.etherscan.io/"
echo ""

echo "📚 Documentation:"
echo "=================="
echo "• README_SETUP.md - Detailed setup guide"
echo "• config.js - Configuration file"
echo "• deploy.js - Deployment script"
echo ""

echo "🎯 Quick Start Commands:"
echo "========================"
echo "• npm install                    # Install dependencies"
echo "• node deploy.js                 # Deploy contract (requires PRIVATE_KEY)"
echo "• npm run test                   # Run tests"
echo "• npm run verify                 # Verify contract on Etherscan"
echo ""

echo "✅ Setup script completed!"
echo "   Please follow the instructions above to complete blockchain setup." 