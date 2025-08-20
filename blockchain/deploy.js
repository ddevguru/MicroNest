const { ethers } = require('hardhat');
const config = require('./config');

async function main() {
  console.log('🚀 Starting MicroNest Smart Contract Deployment...\n');

  // Check configuration
  if (config.infura.projectId === 'YOUR_INFURA_PROJECT_ID') {
    console.error('❌ Please update your Infura Project ID in config.js');
    process.exit(1);
  }

  if (config.contracts.savingsGroup.address === '0x0000000000000000000000000000000000000000') {
    console.log('⚠️  Contract address not set in config.js - will deploy new contract');
  }

  try {
    // Connect to network
    const network = config.networks.sepolia; // Default to Sepolia
    console.log(`📡 Connecting to ${network.name}...`);
    
    const provider = new ethers.providers.JsonRpcProvider(network.rpcUrl);
    const networkInfo = await provider.getNetwork();
    
    if (networkInfo.chainId !== network.chainId) {
      console.error(`❌ Wrong network! Expected ${network.name} (${network.chainId}), got ${networkInfo.chainId}`);
      process.exit(1);
    }
    
    console.log(`✅ Connected to ${network.name}\n`);

    // Get deployer account
    const privateKey = process.env.PRIVATE_KEY;
    if (!privateKey) {
      console.error('❌ Please set PRIVATE_KEY environment variable');
      console.log('Example: export PRIVATE_KEY=0x1234...');
      process.exit(1);
    }

    const wallet = new ethers.Wallet(privateKey, provider);
    const balance = await wallet.getBalance();
    
    console.log(`👤 Deployer: ${wallet.address}`);
    console.log(`💰 Balance: ${ethers.utils.formatEther(balance)} ${network.currency}`);
    
    if (balance.lt(ethers.utils.parseEther('0.01'))) {
      console.error(`❌ Insufficient balance for deployment. Need at least 0.01 ${network.currency}`);
      process.exit(1);
    }
    console.log('');

    // Deploy contract
    console.log('📦 Deploying SavingsGroup contract...');
    
    const SavingsGroup = await ethers.getContractFactory('SavingsGroup');
    const contract = await SavingsGroup.deploy(
      'MicroNest Savings Group',     // name
      'Decentralized savings group management', // description
      ethers.utils.parseEther('1'), // contributionAmount (1 ETH)
      20,                           // maxMembers
      500                           // interestRate (5% = 500 basis points)
    );

    console.log(`⏳ Transaction hash: ${contract.deployTransaction.hash}`);
    console.log('⏳ Waiting for deployment confirmation...');
    
    await contract.deployed();
    
    console.log(`✅ Contract deployed successfully!`);
    console.log(`📍 Address: ${contract.address}`);
    console.log(`🔗 Block Explorer: ${network.blockExplorer}/address/${contract.address}`);
    console.log('');

    // Update config file
    console.log('📝 Updating config.js with new contract address...');
    
    const fs = require('fs');
    let configContent = fs.readFileSync('./config.js', 'utf8');
    configContent = configContent.replace(
      /address: '0x0000000000000000000000000000000000000000'/,
      `address: '${contract.address}'`
    );
    fs.writeFileSync('./config.js', configContent);
    
    console.log('✅ Config file updated!');
    console.log('');

    // Verify contract
    console.log('🔍 Verifying contract on Etherscan...');
    console.log('Note: You may need to verify manually if auto-verification fails');
    console.log('');

    // Display contract info
    console.log('📊 Contract Information:');
    console.log(`   Name: ${await contract.groupName()}`);
    console.log(`   Description: ${await contract.groupDescription()}`);
    console.log(`   Contribution Amount: ${ethers.utils.formatEther(await contract.contributionAmount())} ${network.currency}`);
    console.log(`   Max Members: ${(await contract.maxMembers()).toString()}`);
    console.log(`   Interest Rate: ${(await contract.interestRate()).toString()} basis points`);
    console.log(`   Created At: ${new Date((await contract.createdAt()).toNumber() * 1000).toISOString()}`);
    console.log('');

    console.log('🎉 Deployment completed successfully!');
    console.log('');
    console.log('📋 Next Steps:');
    console.log('1. Update your Flutter app with the new contract address');
    console.log('2. Test the contract functions');
    console.log('3. Share the contract address with your team');
    console.log('');

  } catch (error) {
    console.error('❌ Deployment failed:', error);
    process.exit(1);
  }
}

// Handle errors
process.on('unhandledRejection', (error) => {
  console.error('❌ Unhandled rejection:', error);
  process.exit(1);
});

// Run deployment
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('❌ Deployment failed:', error);
    process.exit(1);
  }); 