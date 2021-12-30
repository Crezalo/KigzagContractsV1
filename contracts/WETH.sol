// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WETH is ERC20{
    string private _name;
    string private _symbol;
    uint256 private _totalSupply = 1000000000 * 10 ** 18;

    constructor() ERC20 ('Wrapped ETH','WETH'){
        // _name = name_;
        // _symbol = symbol_;
        _mint(msg.sender,_totalSupply);
    }
}
