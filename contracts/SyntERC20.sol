// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract SyntERC20 is ERC20, Ownable{
    function mint(address account, uint256 amount) onlyOwner external {
        _mint(account, amount);
    }
    
    function burn(address account, uint256 amount) onlyOwner external {
        _burn(account, amount);
    }
    
    constructor (string memory name_, string memory symbol_) ERC20(name_,symbol_) {}

}