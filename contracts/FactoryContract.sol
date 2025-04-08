// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./MultiSigTokenVault.sol";  // Import MultiSigTokenVault contract

contract MultiSigTokenVaultFactory is Initializable, UUPSUpgradeable, OwnableUpgradeable{
    address[] public vaults;

    event VaultCreated(address vaultAddress, address[] signers, uint256 requiredApprovals, address tokenAddress);

    // Initialize function instead of constructor
    function initialize() public initializer {
    }

    // Function to create a new MultiSigTokenVault instance via proxy
    function createVault(
        address[] memory _signers,
        uint256 _requiredApprovals,
        address _tokenAddress
    ) external returns (address) {
        // Deploy the new vault contract as a UUPS proxy
        MultiSigTokenVault newVault = MultiSigTokenVault(address(0));  // Placeholder

        // Deploy the UUPS proxy and call the initialize function of MultiSigTokenVault
        address vaultProxy = address(newVault);
        // Call initialize function to set the signers, required approvals, and token address
        newVault.initialize(_signers, _requiredApprovals, _tokenAddress);

        // Save the deployed vault address for future reference
        vaults.push(vaultProxy);

        emit VaultCreated(vaultProxy, _signers, _requiredApprovals, _tokenAddress);

        // Return the address of the newly deployed contract
        return vaultProxy;
    }

    // Function to get all deployed vaults (optional)
    function getVaults() external view returns (address[] memory) {
        return vaults;
    }

    // Required for UUPS upgradeable contracts
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
