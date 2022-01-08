// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/ICreatorToken_LT.sol";
import "./interfaces/ICreatorDAO_LT.sol";
import "./interfaces/IXeldoradoCreatorFactory_LT.sol";
import "../libraries/SafeMath.sol";

contract CreatorToken_LT is ERC20, ICreatorToken_LT {
    using SafeMath  for uint;

    address private creatorfactory;
    uint private unlocked;
    address public override creator;
    address public override basetoken;
    address public override dao;

    modifier lock() {
        require(unlocked == 1, 'Xeldorado: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier onlyHolders() {
        require(ICreatorToken_LT(address(this)).balanceOf(msg.sender) > 0 , 'Xeldorado: not a token owner');
        _;
    }

    constructor(address _creator, string memory name, string memory symbol, address _basetoken) ERC20(name,symbol){
        creatorfactory = msg.sender; // creator factory
        creator = _creator;
        unlocked = 1;
        basetoken = _basetoken;
    }

    function initialize(address _dao) public virtual override {
        require(msg.sender==creatorfactory,'Xeldorado: only creator factory allowed');
        require(dao==address(0),'Xeldorado: DAO already added');
        dao = _dao;
    }

    // msg.sender's tokens will be burnt
    function burnMyTokens(uint _amount) public virtual override lock {
        _burn(msg.sender,_amount);
        emit tokensBurnt(address(this), _amount, msg.sender);
    }
    
    function mintTokens(address _to, uint _amount) public virtual override {
        require(msg.sender==dao,'Xeldorado: only dao can mint tokens');
        _mint(_to,_amount);
        emit tokensMinted(address(this), _amount, _to);
    }

    // msg.sender is _to
    // amount in quantity of creator tokens 
    // NOT in 10^18 decimal
    function buyTokens(uint _amount) public virtual override {
        require(IERC20(basetoken).transferFrom(msg.sender, dao, _amount.mul(IXeldoradoCreatorFactory_LT(creatorfactory).creatorSaleFee(creator))),'Xeldorado: base token transfer failed');
        _mint(msg.sender, _amount.mul(10**18));
        ICreatorDAO_LT(dao).currentBalanceUpdate();
    }
}