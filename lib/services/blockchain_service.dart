import 'dart:convert';
import 'dart:math';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BlockchainService {
  // Configuration - Update these with your actual values
  static const String _infuraUrl = 'https://sepolia.infura.io/v3/YOUR_INFURA_PROJECT_ID';
  static const String _contractAddress = '0x0000000000000000000000000000000000000000'; // Placeholder
  
  late Web3Client _client;
  DeployedContract? _contract;
  ContractFunction? _joinGroup;
  ContractFunction? _makeContribution;
  ContractFunction? _requestWithdrawal;
  ContractFunction? _requestLoan;
  ContractFunction? _getMember;
  ContractFunction? _getGroupStats;
  
  bool get isBlockchainEnabled => _contract != null;
  
  BlockchainService() {
    _client = Web3Client(_infuraUrl, http.Client());
    _initializeContract();
  }
  
  void _initializeContract() {
    try {
      // Only initialize if we have a valid contract address
      if (_contractAddress != '0x0000000000000000000000000000000000000000') {
        _contract = DeployedContract(
          ContractAbi.fromJson(_getContractABI(), 'SavingsGroup'),
          EthereumAddress.fromHex(_contractAddress),
        );
        
        _joinGroup = _contract!.function('joinGroup');
        _makeContribution = _contract!.function('makeContribution');
        _requestWithdrawal = _contract!.function('requestWithdrawal');
        _requestLoan = _contract!.function('requestLoan');
        _getMember = _contract!.function('getMember');
        _getGroupStats = _contract!.function('getGroupStats');
      }
    } catch (e) {
      print('Blockchain initialization failed: $e');
      // Continue without blockchain functionality
    }
  }
  
  String _getContractABI() {
    // Return the contract ABI as a JSON string
    return '''
    [
      {
        "inputs": [
          {
            "internalType": "string",
            "name": "_name",
            "type": "string"
          },
          {
            "internalType": "string",
            "name": "_description",
            "type": "string"
          },
          {
            "internalType": "uint256",
            "name": "_contributionAmount",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "_maxMembers",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "_interestRate",
            "type": "uint256"
          }
        ],
        "stateMutability": "nonpayable",
        "type": "constructor"
      },
      {
        "inputs": [],
        "name": "joinGroup",
        "outputs": [],
        "stateMutability": "payable",
        "type": "function"
      },
      {
        "inputs": [],
        "name": "makeContribution",
        "outputs": [],
        "stateMutability": "payable",
        "type": "function"
      },
      {
        "inputs": [
          {
            "internalType": "uint256",
            "name": "amount",
            "type": "uint256"
          },
          {
            "internalType": "string",
            "name": "reason",
            "type": "string"
          }
        ],
        "name": "requestWithdrawal",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [
          {
            "internalType": "uint256",
            "name": "amount",
            "type": "uint256"
          },
          {
            "internalType": "string",
            "name": "purpose",
            "type": "string"
          },
          {
            "internalType": "uint256",
            "name": "dueDate",
            "type": "uint256"
          }
        ],
        "name": "requestLoan",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      }
    ]
    ''';
  }
  
  // Get user's Ethereum wallet address
  Future<String?> getWalletAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('wallet_address');
    } catch (e) {
      print('Error getting wallet address: $e');
      return null;
    }
  }
  
  // Set user's Ethereum wallet address
  Future<bool> setWalletAddress(String address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString('wallet_address', address);
    } catch (e) {
      print('Error setting wallet address: $e');
      return false;
    }
  }
  
  // Get wallet balance
  Future<Object> getWalletBalance(String address) async {
    try {
      final balance = await _client.getBalance(EthereumAddress.fromHex(address));
      return balance;
    } catch (e) {
      print('Error getting wallet balance: $e');
      return BigInt.zero;
    }
  }
  
  // Convert Wei to ETH
  String weiToEth(BigInt wei) {
    final eth = wei / BigInt.from(10).pow(18);
    final remainder = wei % BigInt.from(10).pow(18);
    final decimal = remainder / BigInt.from(10).pow(16);
    return '${eth}.${decimal.toString().padLeft(2, '0')}';
  }
  
  // Convert ETH to Wei
  BigInt ethToWei(String eth) {
    final parts = eth.split('.');
    final whole = BigInt.parse(parts[0]);
    final decimal = parts.length > 1 ? parts[1].padRight(18, '0') : '0';
    return whole * BigInt.from(10).pow(18) + BigInt.parse(decimal);
  }
  
  // Join a savings group
  Future<Map<String, dynamic>> joinGroup(String groupAddress, String contributionAmount) async {
    if (!isBlockchainEnabled) {
      return {
        'success': false, 
        'message': 'Blockchain not configured. Please set up your Infura project ID and contract address.',
        'blockchain_disabled': true
      };
    }
    
    try {
      final walletAddress = await getWalletAddress();
      if (walletAddress == null) {
        return {'success': false, 'message': 'Wallet address not set'};
      }
      
      final amount = ethToWei(contributionAmount);
      
      // Create transaction
      final transaction = await _client.sendTransaction(
        EthPrivateKey.fromHex(walletAddress),
        Transaction(
          to: EthereumAddress.fromHex(groupAddress),
          value: EtherAmount.fromUnitAndValue(EtherUnit.wei, amount),
          gasPrice: EtherAmount.fromUnitAndValue(EtherUnit.gwei, 20),
          maxGas: 200000,
        ),
        chainId: 11155111, // Sepolia testnet
      );
      
      return {
        'success': true,
        'message': 'Transaction submitted successfully',
        'transaction_hash': transaction,
        'amount': contributionAmount,
      };
      
    } catch (e) {
      print('Error joining group: $e');
      return {'success': false, 'message': 'Failed to join group: $e'};
    }
  }
  
  // Make a contribution
  Future<Map<String, dynamic>> makeContribution(String groupAddress, String amount) async {
    if (!isBlockchainEnabled) {
      return {
        'success': false, 
        'message': 'Blockchain not configured. Please set up your Infura project ID and contract address.',
        'blockchain_disabled': true
      };
    }
    
    try {
      final walletAddress = await getWalletAddress();
      if (walletAddress == null) {
        return {'success': false, 'message': 'Wallet address not set'};
      }
      
      final weiAmount = ethToWei(amount);
      
      // Create transaction
      final transaction = await _client.sendTransaction(
        EthPrivateKey.fromHex(walletAddress),
        Transaction(
          to: EthereumAddress.fromHex(groupAddress),
          value: EtherAmount.fromUnitAndValue(EtherUnit.wei, weiAmount),
          gasPrice: EtherAmount.fromUnitAndValue(EtherUnit.gwei, 20),
          maxGas: 150000,
        ),
        chainId: 11155111, // Sepolia testnet
      );
      
      return {
        'success': true,
        'message': 'Contribution submitted successfully',
        'transaction_hash': transaction,
        'amount': amount,
      };
      
    } catch (e) {
      print('Error making contribution: $e');
      return {'success': false, 'message': 'Failed to make contribution: $e'};
    }
  }
  
  // Request withdrawal
  Future<Map<String, dynamic>> requestWithdrawal(String groupAddress, String amount, String reason) async {
    if (!isBlockchainEnabled) {
      return {
        'success': false, 
        'message': 'Blockchain not configured. Please set up your Infura project ID and contract address.',
        'blockchain_disabled': true
      };
    }
    
    try {
      final walletAddress = await getWalletAddress();
      if (walletAddress == null) {
        return {'success': false, 'message': 'Wallet address not set'};
      }
      
      final weiAmount = ethToWei(amount);
      
      // Create transaction
      final transaction = await _client.sendTransaction(
        EthPrivateKey.fromHex(walletAddress),
        Transaction(
          to: EthereumAddress.fromHex(groupAddress),
          value: EtherAmount.fromUnitAndValue(EtherUnit.wei, BigInt.zero),
          gasPrice: EtherAmount.fromUnitAndValue(EtherUnit.gwei, 20),
          maxGas: 200000,
        ),
        chainId: 11155111, // Sepolia testnet
      );
      
      return {
        'success': true,
        'message': 'Withdrawal request submitted successfully',
        'transaction_hash': transaction,
        'amount': amount,
        'reason': reason,
      };
      
    } catch (e) {
      print('Error requesting withdrawal: $e');
      return {'success': false, 'message': 'Failed to request withdrawal: $e'};
    }
  }
  
  // Request loan
  Future<Map<String, dynamic>> requestLoan(String groupAddress, String amount, String purpose, DateTime dueDate) async {
    if (!isBlockchainEnabled) {
      return {
        'success': false, 
        'message': 'Blockchain not configured. Please set up your Infura project ID and contract address.',
        'blockchain_disabled': true
      };
    }
    
    try {
      final walletAddress = await getWalletAddress();
      if (walletAddress == null) {
        return {'success': false, 'message': 'Wallet address not set'};
      }
      
      final weiAmount = ethToWei(amount);
      final dueTimestamp = BigInt.from(dueDate.millisecondsSinceEpoch ~/ 1000);
      
      // Create transaction
      final transaction = await _client.sendTransaction(
        EthPrivateKey.fromHex(walletAddress),
        Transaction(
          to: EthereumAddress.fromHex(groupAddress),
          value: EtherAmount.fromUnitAndValue(EtherUnit.wei, BigInt.zero),
          gasPrice: EtherAmount.fromUnitAndValue(EtherUnit.gwei, 20),
          maxGas: 250000,
        ),
        chainId: 11155111, // Sepolia testnet
      );
      
      return {
        'success': true,
        'message': 'Loan request submitted successfully',
        'transaction_hash': transaction,
        'amount': amount,
        'purpose': purpose,
        'due_date': dueDate.toIso8601String(),
      };
      
    } catch (e) {
      print('Error requesting loan: $e');
      return {'success': false, 'message': 'Failed to request loan: $e'};
    }
  }
  
  // Get member information from smart contract
  Future<Map<String, dynamic>> getMemberInfo(String groupAddress, String memberAddress) async {
    if (!isBlockchainEnabled) {
      return {
        'success': false, 
        'message': 'Blockchain not configured. Please set up your Infura project ID and contract address.',
        'blockchain_disabled': true
      };
    }
    
    try {
      final result = await _client.call(
        contract: _contract!,
        function: _getMember!,
        params: [EthereumAddress.fromHex(memberAddress)],
      );
      
      if (result.isNotEmpty) {
        return {
          'success': true,
          'wallet_address': memberAddress,
          'total_contributed': weiToEth(result[0] as BigInt),
          'last_contribution_date': DateTime.fromMillisecondsSinceEpoch((result[1] as BigInt).toInt() * 1000),
          'is_active': result[2] as bool,
          'trust_score': (result[3] as BigInt).toInt(),
          'joined_at': DateTime.fromMillisecondsSinceEpoch((result[4] as BigInt).toInt() * 1000),
        };
      }
      
      return {'success': false, 'message': 'Member not found'};
      
    } catch (e) {
      print('Error getting member info: $e');
      return {'success': false, 'message': 'Failed to get member info: $e'};
    }
  }
  
  // Get group statistics from smart contract
  Future<Map<String, dynamic>> getGroupStats(String groupAddress) async {
    if (!isBlockchainEnabled) {
      return {
        'success': false, 
        'message': 'Blockchain not configured. Please set up your Infura project ID and contract address.',
        'blockchain_disabled': true
      };
    }
    
    try {
      final result = await _client.call(
        contract: _contract!,
        function: _getGroupStats!,
        params: [],
      );
      
      if (result.isNotEmpty) {
        return {
          'success': true,
          'total_funds': weiToEth(result[0] as BigInt),
          'current_members': (result[1] as BigInt).toInt(),
          'max_members': (result[2] as BigInt).toInt(),
          'contribution_amount': weiToEth(result[3] as BigInt),
          'interest_rate': (result[4] as BigInt).toInt(),
          'created_at': DateTime.fromMillisecondsSinceEpoch((result[5] as BigInt).toInt() * 1000),
        };
      }
      
      return {'success': false, 'message': 'Group stats not found'};
      
    } catch (e) {
      print('Error getting group stats: $e');
      return {'success': false, 'message': 'Failed to get group stats: $e'};
    }
  }
  
  // Get transaction status
  Future<Map<String, dynamic>> getTransactionStatus(String transactionHash) async {
    try {
      final receipt = await _client.getTransactionReceipt(transactionHash);
      
      if (receipt != null) {
        return {
          'success': true,
          'status': receipt.status == 1 ? 'success' : 'failed',
          'gas_used': receipt.gasUsed?.toInt() ?? 0,
          'block_number': receipt.blockNumber?.toString() ?? '0',
          'transaction_hash': transactionHash,
        };
      }
      
      return {'success': false, 'message': 'Transaction not found'};
      
    } catch (e) {
      print('Error getting transaction status: $e');
      return {'success': false, 'message': 'Failed to get transaction status: $e'};
    }
  }
  
  // Create a new wallet
  Future<Map<String, dynamic>> createWallet() async {
    try {
      final credentials = EthPrivateKey.createRandom(Random.secure());
      final address = credentials.address;
      
      // Save wallet address
      await setWalletAddress(address.hex);
      
      return {
        'success': true,
        'wallet_address': address.hex,
        'private_key': '0x${credentials.privateKey.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('')}',
        'message': 'Wallet created successfully',
      };
      
    } catch (e) {
      print('Error creating wallet: $e');
      return {'success': false, 'message': 'Failed to create wallet: $e'};
    }
  }
  
  // Import wallet from private key
  Future<Map<String, dynamic>> importWallet(String privateKey) async {
    try {
      final credentials = EthPrivateKey.fromHex(privateKey);
      final address = credentials.address;
      
      // Save wallet address
      await setWalletAddress(address.hex);
      
      return {
        'success': true,
        'wallet_address': address.hex,
        'message': 'Wallet imported successfully',
      };
      
    } catch (e) {
      print('Error importing wallet: $e');
      return {'success': false, 'message': 'Failed to import wallet: $e'};
    }
  }
  
  // Get gas price estimate
  Future<String> getGasPriceEstimate() async {
    try {
      final gasPrice = await _client.getGasPrice();
      return weiToEth(gasPrice.getInWei);
    } catch (e) {
      print('Error getting gas price: $e');
      return '0.00000002'; // Default fallback
    }
  }
  
  // Get network information
  Future<Map<String, dynamic>> getNetworkInfo() async {
    try {
      final chainId = await _client.getChainId();
      final blockNumber = await _client.getBlockNumber();
      
      String networkName;
      switch (chainId.toInt()) {
        case 1:
          networkName = 'Ethereum Mainnet';
          break;
        case 11155111:
          networkName = 'Sepolia Testnet';
          break;
        case 137:
          networkName = 'Polygon';
          break;
        case 56:
          networkName = 'BSC';
          break;
        default:
          networkName = 'Unknown Network';
      }
      
      return {
        'success': true,
        'network_name': networkName,
        'chain_id': chainId.toInt(),
        'block_number': blockNumber.toString(),
      };
      
    } catch (e) {
      print('Error getting network info: $e');
      return {'success': false, 'message': 'Failed to get network info: $e'};
    }
  }
  
  // Dispose resources
  void dispose() {
    _client.dispose();
  }
} 