//SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract MultiSigTokenVault is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address[] public signers;
    uint256 public requiredApprovals;
    IERC20Upgradeable public token;

    mapping(address => bool) public isSigner;

    struct Transaction {
        address to;
        uint256 amount;
        uint256 approvals;
        bool executed;
    }

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public transactionApprovals;

    //Events
    event TransactionApproved(uint256 indexed txId, address indexed signer);
    event TransactionProposed(
        uint256 indexed txId,
        address indexed proposer,
        address to,
        uint256 amount
    );
    event TransactionExecuted(uint256 indexed txId, address to, uint256 amount);
    event SignerAdded(address indexed newSigner);
    event SignerRemoved(address indexed removedSigner);
    event TokensDeposited(address indexed depositor, uint256 amount);
    event WithdrawToken(address indexed token, address indexed to, uint256 amount);
    event NativeWithdrawn(address indexed to, uint256 amount);

    modifier onlySigner() {
        require(isSigner[msg.sender], "Not an authorized signer");
        _;
    }

    modifier txExists(uint256 txId) {
        require(txId < transactions.length, "Transaction does not exist");
        _;
    }

    modifier notExecuted(uint256 txId) {
        require(!transactions[txId].executed, "Transaction already executed");
        _;
    }

    modifier notApproved(uint256 txId) {
        require(
            !transactionApprovals[txId][msg.sender],
            "Transaction already approved"
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    //Initialize
    function initialize(
        address[] memory _signers,
        uint256 _requiredApprovals,
        address _tokenAddress
    ) public initializer {
        require(_signers.length > 0, "Signers required");
        require(_requiredApprovals <= _signers.length, "Invalid threshold");

        for (uint256 i = 0; i < _signers.length; i++) {
            require(!isSigner[_signers[i]], "Duplicate signer detected");
            isSigner[_signers[i]] = true;
        }

        signers = _signers;
        requiredApprovals = _requiredApprovals;
        token = IERC20Upgradeable(_tokenAddress);

        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
    }

    //Authorization to allow contract upgrades
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    //Add a new signer
    function addSigner(address newSigner) external nonReentrant onlyOwner whenNotPaused {
        require(!isSigner[newSigner], "Already a Signer");
        signers.push(newSigner);
        isSigner[newSigner] = true;

        emit SignerAdded(newSigner);
    }

    //Remove an existing Signer
    function removeSigner(
        address signerToRemove
    ) external nonReentrant onlyOwner whenNotPaused {
        require(isSigner[signerToRemove], "Not a Signer");
        require(
            signers.length - 1 >= requiredApprovals,
            "Cannot remove, Limited!!!"
        );

        isSigner[signerToRemove] = false;

        //Remove the signer from signers array
        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == signerToRemove) {
                signers[i] = signers[signers.length - 1];
                signers.pop();
                break;
            }
        }
        emit SignerRemoved(signerToRemove);
    }

    //Deposit ERC20 tokens into the vault
    function deposit(uint256 amount) external nonReentrant whenNotPaused {
        require(token.balanceOf(msg.sender) >= amount, "Insufficient balance");

        token.safeTransferFrom(msg.sender, address(this), amount);
        emit TokensDeposited(msg.sender, amount);
    }

    //Propose a transaction for approval for signers
    function proposeTransaction(
        address to,
        uint256 amount
    ) external nonReentrant onlySigner whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        transactions.push(
            Transaction({to: to, amount: amount, approvals: 0, executed: false})
        );

        emit TransactionProposed(
            transactions.length - 1,
            msg.sender,
            to,
            amount
        );
    }

    //Approve a proposed Transaction
    function approveTransaction(
        uint256 txId
    ) external onlySigner txExists(txId) notExecuted(txId) notApproved(txId) whenNotPaused {
        Transaction storage txn = transactions[txId];
        transactionApprovals[txId][msg.sender] = true;
        txn.approvals += 1;

        if (txn.approvals >= requiredApprovals) {
            executeTransaction(txId);
        }

        emit TransactionApproved(txId, msg.sender);
    }

    function executeTransaction(
        uint256 txId
    ) internal nonReentrant txExists(txId) notExecuted(txId) whenNotPaused {
        Transaction storage txn = transactions[txId];
        require(
            token.balanceOf(address(this)) >= txn.amount,
            "Insufficient balance"
        );
        token.safeTransfer(txn.to, txn.amount);

        txn.executed = true;

        emit TransactionExecuted(txId, txn.to, txn.amount);
    }

    //View the current signers
    function getSigners() external view returns (address[] memory) {
        return signers;
    }

    // to recieve BNB
    receive() external payable {}

    //Get details about a transaction by ID
    function getTransaction(
        uint256 txId
    )
        external
        view
        txExists(txId)
        returns (address to, uint256 amount, uint256 approvals, bool executed)
    {
        Transaction memory txn = transactions[txId];
        return (txn.to, txn.amount, txn.approvals, txn.executed);
    }

    //Track approvals
    function getApprovalStatus(
        uint256 txId
    )
        external
        view
        txExists(txId)
        returns (
            uint256 approved,
            uint256 pending,
            address[] memory approvedSigners,
            address[] memory pendingSigners
        )
    {
        uint256 approvedCount = 0;
        address[] memory _approvedSigners = new address[](signers.length);
        address[] memory _pendingSigners = new address[](signers.length);
        uint256 approvedIndex = 0;
        uint256 pendingIndex = 0;

        for (uint256 i = 0; i < signers.length; i++) {
            if (transactionApprovals[txId][signers[i]]) {
                _approvedSigners[approvedIndex] = signers[i];
                approvedIndex++;
                approvedCount++;
            } else {
                _pendingSigners[pendingIndex] = signers[i];
                pendingIndex++;
            }
        }

        return (
            approvedCount,
            signers.length - approvedCount,
            _approvedSigners,
            _pendingSigners
        );
    }
     /**
     * @dev Allows the owner to withdraw ERC-20 tokens from this contract.
     * @param _token The address of the ERC-20 token contract.
     * @param _amount The amount of tokens to withdraw.
     * @notice The '_tokenContract' address should not be the zero address.
     */
    function withdrawToken(
        address _token,
        uint256 _amount
    ) external onlyOwner nonReentrant whenNotPaused {
        require(_token != address(0), "Address cant be zero address");
        token.safeTransfer(msg.sender, _amount);
        emit WithdrawToken(_token, msg.sender, _amount);
    }

   function withdrawNative(address payable to, uint256 amount) external onlyOwner nonReentrant whenNotPaused {
        require(to != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= address(this).balance, "Withdrawal amount exceeds native balance");

        to.transfer(amount);

        emit NativeWithdrawn(to, amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
