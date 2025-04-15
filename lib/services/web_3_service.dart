import 'dart:convert';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:flutter/services.dart';

class Web3Service {
  static final Web3Service _instance = Web3Service._internal();
  factory Web3Service() => _instance;

  Web3Client? web3client;
  DeployedContract? _contract;
  late ContractFunction _vote;
  late ContractFunction _hasVoted;
  bool _isInitialized = false;
  late ContractFunction _getVoteCount;
  late ContractFunction _resetVotingState;

  final String _rpcUrl = 'http://192.168.31.83:7545';
  final String _contractAddress =
      '0xeCf04de442e2DB037A88aAd0fE5D3983E5Ab4Ae6'; // Update after deploying new contract
  final Duration _timeout = Duration(seconds: 30);

  Web3Service._internal();

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final httpClient = Client();
      web3client = Web3Client(_rpcUrl, httpClient);

      final abiString =
          await rootBundle.loadString('assets/contracts/VotingSystem.json');
      final contractJson = jsonDecode(abiString);
      final abi = jsonEncode(contractJson['abi']);

      _contract = DeployedContract(
        ContractAbi.fromJson(abi, 'VotingSystem'),
        EthereumAddress.fromHex(_contractAddress),
      );

      _vote = _contract!.function('vote');
      _hasVoted = _contract!.function('hasVoted');
      _getVoteCount = _contract!.function('getVoteCount');
      _resetVotingState = _contract!.function('resetVotingState');

      _isInitialized = true;
    } catch (e) {
      print('Error initializing contract: $e');
      _isInitialized = false;
      await _reconnect();
    }
  }

  Future<void> resetVoterState(String userAddress) async {
    for (int attempts = 0; attempts < 3; attempts++) {
      try {
        await ensureInitialized();

        final credentials = EthPrivateKey.fromHex(
            '5a5e4e84c84f356c5f39bd37c655f05641c910f7788ba78548aebb4fbb3b6e0a');

        final chainId = await web3client!.getChainId();
        await web3client!.sendTransaction(
          credentials,
          Transaction.callContract(
            contract: _contract!,
            function: _resetVotingState,
            parameters: [EthereumAddress.fromHex(userAddress)],
          ),
          chainId: chainId.toInt(),
        );

        return;
      } catch (e) {
        print('Attempt ${attempts + 1} failed: $e');
        if (e.toString().contains('Connection closed')) {
          await _reconnect();
        } else if (attempts == 2) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: 1));
      }
    }
    throw Exception('Failed to reset voter state after multiple attempts');
  }

  Future<void> _reconnect() async {
    try {
      web3client?.dispose();
      web3client = null;
      _isInitialized = false;
      await Future.delayed(Duration(seconds: 1));
      await init();
    } catch (e) {
      print('Error reconnecting: $e');
    }
  }

  Future<bool> checkIfVoted(String userAddress) async {
    for (int attempts = 0; attempts < 3; attempts++) {
      try {
        await ensureInitialized();

        final result = await web3client!.call(
          contract: _contract!,
          function: _hasVoted,
          params: [EthereumAddress.fromHex(userAddress)],
        );
        return result[0] as bool;
      } catch (e) {
        print('Attempt ${attempts + 1} failed: $e');
        if (e.toString().contains('Connection closed')) {
          await _reconnect();
        } else if (attempts == 2) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: 1));
      }
    }
    throw Exception('Failed to check voting status after multiple attempts');
  }

  Future<String> vote(String candidateName, String privateKey) async {
    for (int attempts = 0; attempts < 3; attempts++) {
      try {
        await ensureInitialized();

        final credentials = EthPrivateKey.fromHex(privateKey);

        // Check if already voted
        final hasVoted = await checkIfVoted(credentials.address.hex);
        if (hasVoted) {
          throw Exception('Already voted');
        }

        final chainId = await web3client!.getChainId();
        final transaction = await web3client!.sendTransaction(
          credentials,
          Transaction.callContract(
            contract: _contract!,
            function: _vote,
            parameters: [candidateName],
          ),
          chainId: chainId.toInt(),
        );

        return transaction;
      } catch (e) {
        print('Attempt ${attempts + 1} failed: $e');
        if (e.toString().contains('Connection closed')) {
          await _reconnect();
        } else if (e.toString().contains('Already voted')) {
          rethrow;
        } else if (attempts == 2) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: 1));
      }
    }
    throw Exception('Failed to submit vote after multiple attempts');
  }

  Future<bool> ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
    return _isInitialized;
  }

  Future<int> getVoteCount(String candidateName) async {
    await ensureInitialized();

    try {
      // Add this function to your smart contract
      final voteCountFunction = _contract!.function('getVoteCount');

      final result = await web3client!.call(
        contract: _contract!,
        function: voteCountFunction,
        params: [candidateName],
      );

      return (result[0] as BigInt).toInt();
    } catch (e) {
      print('Error getting vote count: $e');
      return 0;
    }
  }

  Future<void> resetAllVotes() async {
    for (int attempts = 0; attempts < 3; attempts++) {
      try {
        await ensureInitialized();

        final credentials = EthPrivateKey.fromHex(
            // Use your admin private key here
            '5a5e4e84c84f356c5f39bd37c655f05641c910f7788ba78548aebb4fbb3b6e0a');

        final resetFunction = _contract!.function('resetAllVotes');

        final chainId = await web3client!.getChainId();
        await web3client!.sendTransaction(
          credentials,
          Transaction.callContract(
            contract: _contract!,
            function: resetFunction,
            parameters: [],
          ),
          chainId: chainId.toInt(),
        );

        return;
      } catch (e) {
        print('Attempt ${attempts + 1} failed: $e');
        if (e.toString().contains('Connection closed')) {
          await _reconnect();
        } else if (attempts == 2) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: 1));
      }
    }
    throw Exception('Failed to reset all votes after multiple attempts');
  }

  void dispose() {
    web3client?.dispose();
    web3client = null;
    _isInitialized = false;
  }
}
