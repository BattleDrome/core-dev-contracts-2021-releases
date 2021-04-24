// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.1;

contract owned {
    address payable public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor() {
        owner = payable(msg.sender);
    }
    
    function setOwner(address payable _newOwner) internal {
        owner = _newOwner;
    }
}

//Replacement for "changeOwner" in "owned" contract. Need a means for "simpler" contracts to simply have their owner changed
contract simpleTransferrable is owned {
    function changeOwner(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}

contract mortal is owned {
    function eol() public onlyOwner {
        selfdestruct(owner);
    }
}

contract controlled is owned {
    address public controller;
    
    modifier onlyController() {
        require(msg.sender == controller);
        _;
    }
    
    modifier onlyControllerOrOwner() {
        require(msg.sender == controller || msg.sender == owner);
        _;
    }

    constructor() {
        controller = msg.sender;
    }
    
    function setController(address _newController) internal {
        controller = _newController;
    }
    
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}

contract priced {
    modifier costs(uint _amount){
        require(msg.value >= _amount);
        _;
        if (msg.value > _amount) payable(msg.sender).transfer(msg.value - _amount);
    }

    modifier costsWithExcess(uint _amount){
        require(msg.value >= _amount);
        _;
    }
}

