// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

library MultiSig {
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);

    struct Transaction {
        bytes data;
        address to;
        bool executed;
        bool multi;
    }

    // 提交多签消息
    function submitTransaction(Transaction[] storage _transactions, address _to, bytes memory _data, bool _multi) internal {
        _transactions.push(Transaction({
            data: _data,
            to: _to,
            executed: false,
            multi: _multi
        }));

        emit SubmitTransaction(msg.sender, _transactions.length, _data);
    }

    // 确认消息
    function confirmTransaction(
        Transaction[] storage _transactions,
        mapping(uint => mapping(address => bool)) storage _isConfirmed,
        mapping(uint => uint) storage _numConfirmations,
        uint _numConfirmationsRequired,
        uint _txIndex
    ) internal {
        require(!_isConfirmed[_txIndex][msg.sender], "Transaction already confirmed");

        _isConfirmed[_txIndex][msg.sender] = true;
        _numConfirmations[_txIndex]++;

        emit ConfirmTransaction(msg.sender, _txIndex);

        if (_numConfirmations[_txIndex] >= _numConfirmationsRequired) {
            executeTransaction(_transactions, _txIndex);
        }
    }

    // 执行消息
    function executeTransaction(Transaction[] storage _transactions, uint _txIndex) internal {
        require(_txIndex < _transactions.length, "Invalid transaction index");
        require(!_transactions[_txIndex].executed, "Transaction already executed");

        Transaction storage transaction = _transactions[_txIndex];
        transaction.executed = true;

        (bool success, ) = transaction.to.call(transaction.data);
        require(success, "Transaction execution failed");
        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    // 拒绝提案
    function revokeConfirmation(
        Transaction[] storage _transactions,
        mapping(uint => mapping(address => bool)) storage _isConfirmed,
        mapping(uint => uint) storage _numConfirmations,
        uint _txIndex
    ) internal {
        require(_txIndex < _transactions.length, "Invalid transaction index");
        require(_transactions[_txIndex].executed, "Transaction not executed");

        require(_isConfirmed[_txIndex][msg.sender], "Transaction not confirmed");

        _isConfirmed[_txIndex][msg.sender] = false;
        _numConfirmations[_txIndex]--;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }
}