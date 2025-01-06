//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract MultiSigTokenVault is Initializable, UUPSUpgradeable, OwnableUpgradeable{
    address[] public signers;
    uint256 public requiredApprovals;
    IERC20Upgradeable public token;

    mapping(address => bool) public isSigner;

    struct Transaction{
        address to;
        uint256 amount;
        uint256 approvals;
        bool executed;
    }

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public transactionApprovals;

    modifier onlySigner(){
        require(isSigner[msg.sender], "Not asn authorized signer");
        _;
    }

    modifier txExists(uint256 txId){
        require(txId < transactions.length, "Transaction does not exist");
        _;
    }
    
    modifier notExecuted(uint256 txId){
        require(!transactions[txId].executed, "Transaction already executed");
        _;
    }

    modifier notApproved(uint256 txId) {
        require(!transactionApprovals[txId][msg.sender], "Transaction already approved");
        _;
    }

    event TransactionApproved(uint256 indexed txId, address indexed signer);


    //Initialize
    function initialize(
        address[] memory _signers,
        uint256 _requiredApprovals,
        address _tokenAddress
    ) public initializer{
        require(_signers.length > 0, "Signers required");
        require(_requiredApprovals <= _signers.length, "Invalid threshold");

        for(uint256 i =0; i < _signers.length; i++){
            isSigner[_signers[i]] = true;
        }

        signers = _signers;
        requiredApprovals = _requiredApprovals;
        token = IERC20Upgradeable(_tokenAddress);

        __Ownable_init();
    }

    //Authorization to allow contract upgrades
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner{}

    //Add a new signer
    function addSigner(address newSigner) external onlySigner{
        require(!isSigner[newSigner], "Already a Signer");
        signers.push(newSigner);
        isSigner[newSigner] = true;
    }

    //Remove an existing Signer
    function removeSigner(address signerToRemove) external onlySigner{
        require(isSigner[signerToRemove], "Not a Signer");
        require(signers.length - 1 >= requiredApprovals, "Cannot remove, Limited!!!");

        isSigner[signerToRemove] = false;

        //Remove the signer from signers array
        for (uint256 i = 0; i < signers.length; i++){
            if(signers[i] == signerToRemove){
                signers[i] = signers[signers.length - 1];
                signers.pop();
                break;
            }
        }

    }
    
    //Deposit ERC20 tokens into the vault
    function deposit(uint256 amount) external {
        require(token.balanceOf(msg.sender) >= amount, "Insufficient balance");

        token.transferFrom(msg.sender, address(this), amount);
    }

    //Propose a transaction for approval for signers
    function proposeTransaction(address to, uint256 amount) external onlySigner{
        transactions.push(Transaction({
            to: to,
            amount: amount,
            approvals: 0,
            executed: false
        }));
    }
    
    //Approve a proposed Transaction
    function approveTransaction(uint256 txId) 
                external
                onlySigner
                txExists(txId)
                notExecuted(txId)
                notApproved(txId)
        {
            Transaction storage txn = transactions[txId];
            transactionApprovals[txId][msg.sender] = true;
            txn.approvals += 1;

            if(txn.approvals >= requiredApprovals){
                executeTransaction(txId);
            }
        
     emit TransactionApproved(txId, msg.sender);
        }


    //Execute transactions if enough approvals are received
    function executeTransaction(uint256 txId)
                internal
                txExists(txId)
                notExecuted(txId)
        {
            Transaction storage txn = transactions[txId];
            require(txn.approvals >= requiredApprovals, "Not enough approvals");

            txn.executed = true;
            token.transfer(txn.to, txn.amount);
        }

    //View the current signers
    function getSigners() external view returns(address[] memory) {
        return signers;
    }

    //Get details about a transaction by ID
    function getTransaction(uint256 txId)
            external
            view
            txExists(txId)
            returns (
                address to,
                uint256 amount,
                uint256 approvals,
                bool executed
            )
        {
            Transaction memory txn = transactions[txId];
            return(txn.to, txn.amount, txn.approvals, txn.executed);
        }
}