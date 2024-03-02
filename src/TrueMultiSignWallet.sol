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

    // array storing the addresses of the true owners
    address[] public trueOwners;
    //  mapping to quickly check if an address is a true owner of the wallet.
    mapping(address => bool) public isTrueOwner;
    // number of confirmations required to execute a transaction
    uint256 public numConfirmationsRequired;

    // structure of a transaction
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    // mapping from tx index => trueOwner => bool
    mapping(uint256 => mapping(address => bool))
        public isConfirmed; /*keeps track of which transactions have been confirmed by which true owners*/

    // array to store all transactions proposed in the wallet
    Transaction[] public transactions;

    // ensures a transaction can be called by only a true owner of the wallet
    modifier onlyTrueOwner() {
        require(isTrueOwner[msg.sender], "not true owner!");
        _;
    }

    // checks a transaction exists
    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    // ensures a transaction has not been executed
    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    // checks a transaction has not been confirmed by msg.sender
    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    constructor(
        address[] memory _trueOwners,
        uint256 _numConfirmationsRequired
    ) {
        require(_trueOwners.length > 0, "true owners required!");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _trueOwners.length,
            "invalid number of required confirmations"
        );

        for (uint256 i = 0; i < _trueOwners.length; i++) {
            address trueOwner = _trueOwners[i];

            require(trueOwner != address(0), "invalid owner!");
            require(!isTrueOwner[trueOwner], "owner not unique!");

            isTrueOwner[trueOwner] = true;
            trueOwners.push(trueOwner);
        }
        numConfirmationsRequired = _numConfirmationsRequired;
    }
}
