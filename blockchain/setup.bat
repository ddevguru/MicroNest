@echo off
echo 🚀 MicroNest Blockchain Setup Script
echo =====================================
echo.

REM Check if Node.js is installed
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js is not installed. Please install Node.js first.
    echo    Download from: https://nodejs.org/
    pause
    exit /b 1
)

REM Check if npm is installed
npm --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ npm is not installed. Please install npm first.
    pause
    exit /b 1
)

echo ✅ Node.js and npm are installed
echo.

REM Install dependencies
echo 📦 Installing dependencies...
npm install
echo.

REM Check if config.js exists
if not exist "config.js" (
    echo ❌ config.js not found. Please run this script from the blockchain directory.
    pause
    exit /b 1
)

echo 🔧 Configuration Setup
echo ======================
echo.

REM Check if Infura project ID is set
findstr "YOUR_INFURA_PROJECT_ID" config.js >nul
if %errorlevel% equ 0 (
    echo ⚠️  Infura Project ID not configured
    echo    Please update config.js with your Infura project ID
    echo    Get it from: https://infura.io/
    echo.
)

REM Check if contract address is set
findstr "0x0000000000000000000000000000000000000000" config.js >nul
if %errorlevel% equ 0 (
    echo ⚠️  Contract address not configured
    echo    Please deploy the contract first or update the address in config.js
    echo.
)

echo 📋 Setup Instructions:
echo ======================
echo.
echo 1. Get Infura Project ID:
echo    - Go to https://infura.io/
echo    - Create account and project
echo    - Copy Project ID from Settings → Keys
echo    - Update config.js
echo.
echo 2. Deploy Smart Contract:
echo    - Option A: Use Remix IDE (easiest)
echo    - Option B: Use this script with Hardhat
echo.
echo 3. Update Contract Address:
echo    - Copy deployed contract address
echo    - Update config.js
echo.
echo 4. Test Blockchain Integration:
echo    - Run the Flutter app
echo    - Try creating/joining groups
echo.

echo 🔗 Useful Links:
echo =================
echo • Infura: https://infura.io/
echo • Remix IDE: https://remix.ethereum.org/
echo • Sepolia Faucet: https://sepoliafaucet.com/
echo • Sepolia Etherscan: https://sepolia.etherscan.io/
echo.

echo 📚 Documentation:
echo ==================
echo • README_SETUP.md - Detailed setup guide
echo • config.js - Configuration file
echo • deploy.js - Deployment script
echo.

echo 🎯 Quick Start Commands:
echo ========================
echo • npm install                    # Install dependencies
echo • node deploy.js                 # Deploy contract (requires PRIVATE_KEY)
echo • npm run test                   # Run tests
echo • npm run verify                 # Verify contract on Etherscan
echo.

echo ✅ Setup script completed!
echo    Please follow the instructions above to complete blockchain setup.
pause 