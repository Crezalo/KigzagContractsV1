// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERCToken is ERC20{
    string private _name;
    string private _symbol;
    uint256 private _totalSupply = 111888 * 10 ** 18;

    constructor() ERC20 ('MYToken','MTN'){
        // _name = name_;
        // _symbol = symbol_;
        _mint(msg.sender,111888 * 10 ** 18);
    }
}


