// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "contracts/MultiSig.sol";

contract Controller {
    modifier OnlyAdministrator() {
        require(isAdministrator[msg.sender], "Only the administrator can use");
        _;
    }

    modifier OnlyOwner() {
        require(isOwner[msg.sender], "Only the owner can use");
        _;
    }

    uint256 private numConfirmationsRequired;
    address private marketAddress;

    address[] private administrators;
    MultiSig.Transaction[] private transactions;

    mapping(address => bool) private isOwner;
    mapping(address => bool) private isAdministrator;
    mapping(uint => uint) private numConfirmations;
    mapping(uint => mapping(address => bool)) private isConfirmed;


    constructor(address _market, address[] memory _admin) {
        marketAddress = _market;

        for (uint8 index = 0; index < _admin.length; index++) {
            if (!isAdministrator[_admin[index]]) {
                administrators.push(_admin[index]);
                isAdministrator[_admin[index]] = true;
            }
        }
    }

    // 设置最小确认数
    function setConfirmationsRequired(uint256 _value) external OnlyOwner {
        require(((_value >= 1)&&(_value <= administrators.length)), "required number must >= 1 or <= controller member.");
        numConfirmationsRequired = _value;
    }

    // 设置admin，需要改进
    function setAdministrators(address[] memory _admin) external OnlyOwner {
        while ( 0 == administrators.length) {
            isAdministrator[administrators[administrators.length-1]] = false;
            administrators.pop();
        }
        for (uint8 index = 0; index < _admin.length; index++) {
            if (!isAdministrator[_admin[index]]) {
                administrators.push(_admin[index]);
                isAdministrator[_admin[index]] = true;
            }
        }
    }

    // 获取多签池交易
    function getTransactions() public OnlyAdministrator view returns (MultiSig.Transaction[] memory) {
        return transactions;
    }

    // 提交设置拥有者提案
    function commitSetOwner(address _newOwner) external OnlyAdministrator returns (uint) {
        MultiSig.submitTransaction(
            transactions,
            marketAddress,
            abi.encodeWithSignature("setOwner(address)", _newOwner),
            true
        );
        return transactions.length;
    }

    // 确认提案
    function confirmTransaction(uint _txIndex) external OnlyAdministrator {
        MultiSig.confirmTransaction(
            transactions, 
            isConfirmed, 
            numConfirmations, 
            numConfirmationsRequired,
            _txIndex
        );
    }

    // 拒绝提案
    function revokeConfirmation(uint _txIndex) external OnlyAdministrator {
        MultiSig.revokeConfirmation(
            transactions, 
            isConfirmed, 
            numConfirmations, 
            _txIndex
        );
    }
}