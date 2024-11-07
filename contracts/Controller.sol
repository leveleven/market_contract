// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.22;

import "contracts/MultiSig.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Controller is Ownable {
    modifier OnlyAdministrator() {
        require(isAdministrator[msg.sender], "Only the administrator can use");
        _;
    }

    uint256 private numConfirmationsRequired;

    address[] private administrators;
    MultiSig.Transaction[] private transactions;

    mapping(address => bool) private isAdministrator;
    mapping(uint => uint) private numConfirmations;
    mapping(uint => mapping(address => bool)) private isConfirmed;


    constructor(address[] memory _admin) 
        Ownable(msg.sender)
    {
        numConfirmationsRequired = _admin.length;

        for (uint8 index = 0; index < numConfirmationsRequired; index++) {
            if (!isAdministrator[_admin[index]]) {
                administrators.push(_admin[index]);
                isAdministrator[_admin[index]] = true;
            }
        }
    }

    // 获取最小签名数
    function getNumConfirmationsRequired() external view returns (uint256) {
        return numConfirmationsRequired;
    }

    // 设置最小确认数
    function setConfirmationsRequired(uint256 _value) external onlyOwner {
        require(((_value >= 1)&&(_value <= administrators.length)), "required number must >= 1 or <= controller member.");
        numConfirmationsRequired = _value;
    }

    // 获取administrators
    function getAdministrators() external view returns(address[] memory) {
        return administrators;
    }

    // 设置administrators
    function setAdministrators(address[] memory _admin) external onlyOwner {
        for (uint8 index = 0; index < administrators.length; index++ ) {
            isAdministrator[administrators[index]] = false;
        }
        delete administrators;
        for (uint8 index = 0; index < _admin.length; index++) {
            if (!isAdministrator[_admin[index]]) {
                administrators.push(_admin[index]);
                isAdministrator[_admin[index]] = true;
            }
        }
    }

    // 获取多签池交易
    function getTransactions() external view returns (MultiSig.Transaction[] memory) {
        return transactions;
    }

    // 提交设置拥有者提案
    function commitSetMarketOwner(address _market, address _newOwner) external OnlyAdministrator returns (uint) {
        MultiSig.submitTransaction(
            transactions,
            _market,
            abi.encodeWithSignature("setOwner(address)", _newOwner),
            isConfirmed, 
            numConfirmations, 
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