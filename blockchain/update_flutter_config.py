#!/usr/bin/env python3
"""
MicroNest Blockchain Configuration Updater
Updates Flutter blockchain service with contract address and Infura settings
"""

import os
import re
import sys
from pathlib import Path

def update_flutter_config(contract_address, infura_project_id):
    """Update Flutter blockchain service configuration"""
    
    # Path to Flutter blockchain service
    flutter_service_path = Path("../lib/services/blockchain_service.dart")
    
    if not flutter_service_path.exists():
        print(f"❌ Flutter service not found at: {flutter_service_path}")
        return False
    
    try:
        # Read current file
        with open(flutter_service_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Update Infura URL
        old_infura_url = r'https://sepolia\.infura\.io/v3/YOUR_INFURA_PROJECT_ID'
        new_infura_url = f'https://sepolia.infura.io/v3/{infura_project_id}'
        
        if old_infura_url in content:
            content = content.replace(old_infura_url, new_infura_url)
            print(f"✅ Updated Infura URL with project ID: {infura_project_id}")
        else:
            print("⚠️  Infura URL already updated or not found")
        
        # Update contract address
        old_contract_address = r'0x0000000000000000000000000000000000000000'
        if old_contract_address in content:
            content = content.replace(old_contract_address, contract_address)
            print(f"✅ Updated contract address: {contract_address}")
        else:
            print("⚠️  Contract address already updated or not found")
        
        # Write updated content
        with open(flutter_service_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print("✅ Flutter blockchain configuration updated successfully!")
        return True
        
    except Exception as e:
        print(f"❌ Error updating Flutter config: {e}")
        return False

def main():
    print("🚀 MicroNest Blockchain Configuration Updater")
    print("=============================================")
    print()
    
    # Get configuration from user
    print("Please provide the following information:")
    print()
    
    # Get Infura Project ID
    infura_project_id = input("Enter your Infura Project ID: ").strip()
    if not infura_project_id or infura_project_id == "YOUR_INFURA_PROJECT_ID":
        print("❌ Invalid Infura Project ID")
        return False
    
    # Get Contract Address
    contract_address = input("Enter your deployed contract address: ").strip()
    if not contract_address or contract_address == "0x0000000000000000000000000000000000000000":
        print("❌ Invalid contract address")
        return False
    
    # Validate contract address format
    if not re.match(r'^0x[a-fA-F0-9]{40}$', contract_address):
        print("❌ Invalid contract address format. Must be 40 hex characters with 0x prefix")
        return False
    
    print()
    print("📋 Configuration Summary:")
    print(f"   Infura Project ID: {infura_project_id}")
    print(f"   Contract Address: {contract_address}")
    print()
    
    # Confirm update
    confirm = input("Proceed with updating Flutter configuration? (y/N): ").strip().lower()
    if confirm not in ['y', 'yes']:
        print("❌ Update cancelled")
        return False
    
    print()
    
    # Update Flutter config
    if update_flutter_config(contract_address, infura_project_id):
        print()
        print("🎉 Configuration update completed!")
        print()
        print("📋 Next Steps:")
        print("1. Restart your Flutter app")
        print("2. Test blockchain functionality")
        print("3. Try creating or joining a group")
        print()
        print("🔗 Verify your contract:")
        print(f"   https://sepolia.etherscan.io/address/{contract_address}")
        return True
    else:
        print("❌ Configuration update failed")
        return False

if __name__ == "__main__":
    try:
        success = main()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n❌ Update cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        sys.exit(1) 