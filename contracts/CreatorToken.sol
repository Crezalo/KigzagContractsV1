// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CreatorToken is ERC20{
    
    address private admin;

    constructor(string memory name, string memory symbol, address creator, address vault) ERC20(name,symbol){
        _mint(creator,2853312 * 10 ** 16);
        _mint(vault,9035488 * 10 ** 16);
        admin == msg.sender;
    }
}