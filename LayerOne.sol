// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "https://github.com/LayerZero-Labs/solidity-examples/blob/main/contracts/lzApp/NonblockingLzApp.sol";
import "StableToken.sol";

/*
    LayerZero Sepolia
      lzChainId:10161 lzEndpoint:0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1
      contract: 
    LayerZero Goerli
      lzChainId:10121 lzEndpoint:0xbfD2135BFfbb0B5378b56643c2Df8a87552Bfa23
      contract: 
*/

contract LayerOne is NonblockingLzApp {
    address private constant _LZENDPOINT = 0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1; // sepolia
    uint16 private constant _DESTCHAINID = 10121; // goerli

    StableToken public immutable Stablecoin;

    mapping(address => uint256) public input;
    mapping(address => uint256) public output;

    error CallFail();
    error InsufficientGas();

    constructor(StableToken _stablecoinAddr) NonblockingLzApp(_LZENDPOINT) {
        Stablecoin = _stablecoinAddr;
    }

    function _nonblockingLzReceive(uint16, bytes memory, uint64, bytes memory _payload) internal override {
        (address toAddress, uint256 amount) = abi.decode(_payload, (address, uint256));

        output[toAddress] = output[toAddress] + amount;
        Stablecoin.transfer(toAddress, amount);
    }

    function bridge(uint256 _amount) public payable {
        input[msg.sender] = input[msg.sender] + _amount;

        // Need to approve before
        Stablecoin.transferFrom(msg.sender, address(this), _amount);

        bytes memory payload = abi.encode(msg.sender, _amount);
        uint16 version = 1;
        uint256 gasForLzReceive = 350000;
        bytes memory adapterParams = abi.encodePacked(version, gasForLzReceive);

        (uint256 messageFee,) = lzEndpoint.estimateFees(_DESTCHAINID, address(this), payload, false, adapterParams);
        if (messageFee > msg.value) revert InsufficientGas();

        _lzSend(_DESTCHAINID, payload, payable(msg.sender), address(0x0), adapterParams, msg.value);
    }

    function trustAddress(address _otherContract) public onlyOwner {
        trustedRemoteLookup[_DESTCHAINID] = abi.encodePacked(_otherContract, address(this));
    }

    function estimateFees(uint256 _amount) external view returns (uint256) {
        bytes memory payload = abi.encode(msg.sender, _amount);
        uint16 version = 1;
        uint256 gasForLzReceive = 350000;
        bytes memory adapterParams = abi.encodePacked(version, gasForLzReceive);

        (uint256 messageFee,) = lzEndpoint.estimateFees(_DESTCHAINID, address(this), payload, false, adapterParams);
        return messageFee;
    }
}
