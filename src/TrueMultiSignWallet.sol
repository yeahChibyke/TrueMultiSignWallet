// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TrueMultiSignWallet {
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(
        address indexed trueOwner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    event ConfirmTransaction(
        address indexed trueOwner,
        uint256 indexed txIndex
    );
    event RevokeConfirmation(
        address indexed trueOwner,
        uint256 indexed txIndex
    );
    event ExecuteTransaction(
        address indexed trueOwner,
        uint256 indexed txIndex
    );

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

    // allows the contract to receive Ether and emits a `Deposit` event
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    // allows a true owner to propose a new transaction by creating a new transaction and adding it to `transactions` array
    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public onlyTrueOwner {
        uint256 txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    // allows a true owner to confirm a proposed transaction if it exists, is not executed, and has not been confirmed by them yet
    function confirmTransaction(
        uint256 _txIndex
    )
        public
        onlyTrueOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    // if a transaction has the required number of confirmations, an owner can execute it. this sends the Ether and/or data to the destination address
    function executeTransaction(
        uint256 _txIndex
    ) public onlyTrueOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute transaction!"
        );

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "transaction failed!");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    // allows an owner to revoke their confirmation for a transaction, provided it hasn't been executed yet
    function revokeConfirmation(
        uint256 _txIndex
    ) public onlyTrueOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(
            isConfirmed[_txIndex][msg.sender],
            "transaction not confirmed!"
        );

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    // returns the list of true owners
    function getTrueOwners() public view returns (address[] memory) {
        return trueOwners;
    }

    // returns the number of transactions proposed in the wallet
    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }
}
