//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract SparkoutToken is ERC20Upgradeable, UUPSUpgradeable, OwnableUpgradeable {
    function initialize(uint256 initialSupply) public initializer{
        __ERC20_init("Sparkout" , "SPK");
        __Ownable_init();
        _mint(msg.sender, initialSupply);
    }
    
    //Authorization to allow contract upgrades
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner{}

    //Mint
    function mint(address to, uint256 amount) external onlyOwner{
        _mint(to, amount);
    }
    //Burn
    function burn(address from , uint256 amount) external onlyOwner{
        _burn(from, amount);
    }
}
