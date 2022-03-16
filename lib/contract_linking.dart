import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

class ContractLinking extends ChangeNotifier {
  final String _rpcUrl = "http://10.0.2.2:7545";
  final String _wsUrl = "ws://10.0.2.2:7545/";
  final String _privateKey =
      "3fe98aa9098dee8f5db63b4aba7bf08db960919ba82f5360f43984151cd8ec34";
  Web3Client? _client;
  bool isLoading = true;

  String? _abiCode;
  EthereumAddress? _contractAddress;

  Credentials? _credentials;

  DeployedContract? _contract;
  ContractFunction? _countryName;
  ContractFunction? _currentPopulation;
  ContractFunction? _set;
  ContractFunction? _decrement;
  ContractFunction? _increment;

  String? countryName;
  String? currentPopulation;

  ContractLinking() {
    initialSetup();
  }

  initialSetup() async {
    _client = Web3Client(_rpcUrl, Client(), socketConnector: () {
      return IOWebSocketChannel.connect(_wsUrl).cast<String>();
    });
    await getAbi();
    await getCredentials();
    await getDeployedContract();
  }

  Future<void> getAbi() async {
    // Reading the contract abi
    final abiStringFile =
        await rootBundle.loadString("src/artifacts/Population.json");
    final jsonAbi = jsonDecode(abiStringFile);
    _abiCode = jsonEncode(jsonAbi["abi"]);
    _contractAddress =
        EthereumAddress.fromHex(jsonAbi["networks"]["5777"]["address"]);
  }

  Future<void> getCredentials() async {
    _credentials = await _client?.credentialsFromPrivateKey(_privateKey);
  }

  Future<void> getDeployedContract() async {
    // Telling Web3dart where our contract is declared.
    _contract = DeployedContract(
        ContractAbi.fromJson(_abiCode!, "Population"), _contractAddress!);

    // Extracting the functions, declared in contract.
    _countryName = _contract?.function("countryName");
    _currentPopulation = _contract?.function("currentPopulation");
    _set = _contract?.function("set");
    _decrement = _contract?.function("decrement");
    _increment = _contract?.function("increment");

    getData();
  }

  getData() async {
    // Getting the current name and population declared in the smart contract.
    List name = await _client!
        .call(contract: _contract!, function: _countryName!, params: []);
    List population = await _client!
        .call(contract: _contract!, function: _currentPopulation!, params: []);
    countryName = name[0];
    currentPopulation = population[0].toString();
    print("$countryName , $currentPopulation");
    isLoading = false;
    notifyListeners();
  }

  addData(String nameData, BigInt countData) async {
    // Setting the countryName  and currentPopulation defined by the user
    isLoading = true;
    notifyListeners();
    await _client!.sendTransaction(
        _credentials!,
        Transaction.callContract(
            contract: _contract!,
            function: _set!,
            parameters: [nameData, countData]));
    getData();
  }

  increasePopulation(int incrementBy) async {
    // Increasing the currentPopulation
    isLoading = true;
    notifyListeners();
    await _client!.sendTransaction(
        _credentials!,
        Transaction.callContract(
            contract: _contract!,
            function: _increment!,
            parameters: [BigInt.from(incrementBy)]));
    getData();
  }

  decreasePopulation(int decrementBy) async {
    // Decreasing the currentPopulation
    isLoading = true;
    notifyListeners();
    await _client!.sendTransaction(
        _credentials!,
        Transaction.callContract(
            contract: _contract!,
            function: _decrement!,
            parameters: [BigInt.from(decrementBy)]));
    getData();
  }
}
