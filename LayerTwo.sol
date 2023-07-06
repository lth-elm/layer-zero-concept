// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "https://github.com/LayerZero-Labs/solidity-examples/blob/main/contracts/lzApp/NonblockingLzApp.sol";

/*
    LayerZero Sepolia
      lzChainId:10161 lzEndpoint:0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1
      contract: 
    LayerZero Goerli
      lzChainId:10121 lzEndpoint:0xbfD2135BFfbb0B5378b56643c2Df8a87552Bfa23
      contract: 
*/

contract LayerTwo is NonblockingLzApp {
    address private constant _LZENDPOINT = 0xbfD2135BFfbb0B5378b56643c2Df8a87552Bfa23; // goerli
    uint16 private constant _DESTCHAINID = 10161; // sepolia

    mapping(address => uint256) public accountBalance;

    error InsufficientFunds();
    error InsufficientGas();

    constructor(address _otherContract) NonblockingLzApp(_LZENDPOINT) {
        trustAddress(_otherContract);
    }

    function _nonblockingLzReceive(uint16, bytes memory, uint64, bytes memory _payload) internal override {
        (address fromAddress, uint256 amount) = abi.decode(_payload, (address, uint256));
        accountBalance[fromAddress] = accountBalance[fromAddress] + amount;
    }

    function transfer(address _to, uint256 _amount) external {
        uint256 balance = accountBalance[msg.sender];
        if (_amount > balance) revert InsufficientFunds();

        accountBalance[msg.sender] = balance - _amount;
        accountBalance[_to] = accountBalance[_to] + _amount;
    }

    function settle(uint256 _amount) public payable {
        uint256 balance = accountBalance[msg.sender];
        if (_amount > balance) revert InsufficientFunds();

        accountBalance[msg.sender] = balance - _amount;

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
