// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface ICreatorToken_LT is IERC20, IERC20Metadata {
    event tokensMinted(address ctoken, uint amount, address to);
    event tokensBurnt(address ctoken, uint amount, address _of);

    function creator() external view returns(address);
    function dao() external view returns(address);

    // only creator factory can call
    function initialize(address _dao) external;

    // only dao can call 
    function mintTokens(address _to, uint _amount) external; 

    // caller's token will be burnt
    function burnMyTokens(uint _amount) external;

    // caller will buy token against base token
    function buyTokens(uint _amount, address _basetoken) external;
}