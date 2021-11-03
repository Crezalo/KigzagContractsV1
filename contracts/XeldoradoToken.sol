// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Xeldorado minted a total of 1 billion X at its launch, which it expected to distribute over the course of four years. 
// Sixty percent of all X will be distributed to community members, while the remaining 40% will be for investors, advisers and Xeldorado team members. 
// Once the total of 1 billion X is distributed, X will be an inflationary token with a perpetual inflation rate of 2%

// this is a test contract which paves way for Xeldorado to launch an exchange utility + governance 
// token to allow token holders to trade at discounted fees in future however the support for this
// is already available in the core contracts including Vault and Pair Contract.
// Currently this part is switched off

contract XeldoradoToken is ERC20{
    string private _name;
    string private _symbol;
    uint256 private _totalSupply = 10 ** 27;
    address private admin;

    constructor() ERC20 ('Xeldorado','X'){
        // _name = name_;
        // _symbol = symbol_;
        admin = msg.sender;
        _mint(admin,_totalSupply);
    }
    
    function burnTokens(address _of, uint _amount) public {
        require(msg.sender==admin,'Xeldorado: only admin can burn tokens');
        require(allowance(_of, admin) >= _amount, 'Xeldorado: need allowance approval');
        _burn(_of,_amount);
    }
    
    function mintTokens(address _to, uint _amount) public {
        require(msg.sender==admin,'Xeldorado: only vault can burn tokens');
        _mint(_to,_amount);
    }
}


