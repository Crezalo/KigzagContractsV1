// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

interface ICreatorToken {
    function burnTokens(address _of, uint _amount) external;
    function mintTokens(address _to, uint _amount) external;
}