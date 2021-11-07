// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/ICreatorToken.sol";

contract CreatorToken is ERC20, ICreatorToken {
    
    address private admin;
    address private vault;

    constructor(string memory name, string memory symbol, address _creatorVestingVault, address _vault) ERC20(name,symbol){
        _mint(_creatorVestingVault, 26685312 * 10 ** 16);
        _mint(_vault,84503488 * 10 ** 16);
        admin == msg.sender;
        vault = _vault;
    }
    
    function burnTokens(address _of, uint _amount) public virtual override {
        require(msg.sender==vault,'Xeldorado: only vault can burn tokens');
        _burn(_of,_amount);
    }
    
    function mintTokens(address _to, uint _amount) public virtual override {
        require(msg.sender==vault,'Xeldorado: only vault can burn tokens');
        _mint(_to,_amount);
    }
}