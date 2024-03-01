// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TrueMultiSignWallet {
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(
        address indexed trueOwner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        bytes data
    );
    event ConfirmTransaction(address indexed trueOwner, uint indexed txIndex);
    event RevokeConfirmation(address indexed trueOwner, uint indexed txIndex);
    event ExecuteTransaction(address indexed trueOwner, uint indexed txIndex);

    address[] public trueOwners;
    mapping(address => bool) public isTrueOwner;
    uint public numConfirmationsRequired;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    // mapping from tx index => trueOwner => bool
    mapping(uint => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    modifier onlyTrueOwner() {
        require(isTrueOwner[msg.sender], "not true owner!");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }
}
