// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICreatorToken is IERC20 {
    function burnTokens(address _of, uint _amount) external;
    function mintTokens(address _to, uint _amount) external;
}