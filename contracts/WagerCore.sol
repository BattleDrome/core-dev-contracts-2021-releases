// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.1;

import "./Utils.sol";
import "./EventCore.sol";
import "./WarriorCore.sol";

contract WagerCore is owned, simpleTransferrable, controlled, mortal {

    //////////////////////////////////////////////////////////////////////////////////////////
    // Config
    //////////////////////////////////////////////////////////////////////////////////////////

    uint constant MIN_WAGER_AMOUNT = 100000 gwei;
    uint constant WINNING_WARRIOR_DIVISOR = 10;

    //////////////////////////////////////////////////////////////////////////////////////////
    // Data Structures
    //////////////////////////////////////////////////////////////////////////////////////////
    
    struct WagerData {
        address payable owner;
        uint amount;
        uint warrior;
        bool won;
    }

    struct EventData {
        WagerData[] wagers;
        mapping(address=>uint) ownerWagers;
        mapping(address=>bool) ownerPresent;
        uint[] winningWagers;
        bool winnersCalculated;
        bool paid;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // State
    //////////////////////////////////////////////////////////////////////////////////////////

    mapping(uint=>EventData) eventDB;
    EventCore public eventCore;
    WarriorCore public warriorCore;

    //////////////////////////////////////////////////////////////////////////////////////////
    // Modifiers
    //////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////////////////////////
    // Events
    //////////////////////////////////////////////////////////////////////////////////////////
    
    event NewWager(
        address indexed owner,
        uint amount,
        uint indexed warriorID,
        uint indexed eventID,
        uint32 timeStamp
        );

    event AddWager(
        address indexed owner,
        uint amount,
        uint indexed eventID,
        uint32 timeStamp
        );

    event WinnersCalculated(
        address indexed caller,
        uint indexed eventID,
        uint count,
        bool warrior,
        uint32 timeStamp
        );
    
    event PaymentTriggered(
        address indexed caller,
        uint indexed eventID,
        uint32 timeStamp
        );

    event WarriorPaid(
        uint indexed warriorID,
        uint indexed eventID,
        uint amount,
        uint32 timeStamp
        );

    event WinnerPaid(
        address indexed winner,
        uint indexed eventID,
        uint amount,
        uint32 timeStamp
        );
    
    event HouseDonation(
        uint indexed eventID,
        uint amount,
        uint32 timeStamp
        );

    //////////////////////////////////////////////////////////////////////////////////////////
    // Wager Constructor
    //////////////////////////////////////////////////////////////////////////////////////////
    function wager(uint _warrior, uint _event) public payable returns(uint) {
        require(canWager(msg.value, _warrior, _event),"!CANWAGER");
        if (ownerPresent(_event, msg.sender)) {
            uint existingWagerID = getWagerIDByOwner(_event,msg.sender);
            eventDB[_event].wagers[existingWagerID].amount += msg.value;
            emit AddWager(msg.sender, msg.value, _event, uint32(block.timestamp));
            return existingWagerID;          
        } else {
            WagerData memory newWager = WagerData(payable(msg.sender), msg.value, _warrior, false);
            eventDB[_event].wagers.push(newWager);
            uint newWagerID = eventDB[_event].wagers.length-1;
            eventDB[_event].ownerPresent[msg.sender] = true;
            eventDB[_event].ownerWagers[msg.sender] = newWagerID;
            emit NewWager(msg.sender, msg.value, _warrior, _event, uint32(block.timestamp));
            return newWagerID;
        }
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Getters
    //////////////////////////////////////////////////////////////////////////////////////////

    function getWager(uint eventID, uint wagerID) internal view returns(WagerData storage) {
        return eventDB[eventID].wagers[wagerID];
    }

    function getWagerID(uint eventID) public view returns(uint) {
        require(ownerPresent(eventID,msg.sender),"MISSING_OWNER");
        return eventDB[eventID].ownerWagers[msg.sender];
    }
    
    function getWagerIDByOwner(uint eventID, address owner) public view returns(uint) {
        require(ownerPresent(eventID,owner),"MISSING_OWNER_LOOKUP");
        return eventDB[eventID].ownerWagers[owner];
    }

    function ownerPresent(uint eventID, address owner) public view returns(bool) {
        return eventDB[eventID].ownerPresent[owner];
    }

    function canWager(uint _amount, uint _warrior, uint _event) public view returns(bool) {
        return (
            _amount > MIN_WAGER_AMOUNT &&
            eventCore.getEventCount() > _event &&
            warriorCore.getGlobalWarriorCount() > _warrior &&
            eventCore.getState(_event) == EventCore.EventState.New &&
            eventCore.checkParticipation(_event,_warrior) &&
            (
                !ownerPresent(_event,msg.sender) ||
                _warrior == getWager(_event,getWagerIDByOwner(_event,msg.sender)).warrior
            )
        );
    }

    function getWagerAmount(uint eventID, uint wagerID) public view returns(uint) {
        return getWager(eventID,wagerID).amount;
    }
    
    function getWagerWarrior(uint eventID, uint wagerID) public view returns(uint) {
        return getWager(eventID,wagerID).warrior;
    }
    
    function getWagerWinner(uint eventID, uint wagerID) public view returns(bool) {
        return getWager(eventID,wagerID).won;
    }
    
    function getWagerOwner(uint eventID, uint wagerID) public view returns(address payable) {
        return getWager(eventID,wagerID).owner;
    }

    function getWagerCount(uint eventID) public view returns(uint) {
        return eventDB[eventID].wagers.length;
    }

    function getEventTotalWagerPool(uint eventID) public view returns(uint) {
        uint totalPool = 0;
        for(uint i=0;i<eventDB[eventID].wagers.length;i++) {
            totalPool += eventDB[eventID].wagers[i].amount;
        }
        return totalPool;
    }

    function getEventTotalLosersWagerPool(uint eventID) public view returns(uint) {
        uint totalPool = 0;
        for(uint i=0;i<eventDB[eventID].wagers.length;i++) {
            if(!eventDB[eventID].wagers[i].won){
                totalPool += eventDB[eventID].wagers[i].amount;
            }
        }
        return totalPool;
    }
    
    function getEventTotalWinnersWagerPool(uint eventID) public view returns(uint) {
        uint totalPool = 0;
        for(uint i=0;i<eventDB[eventID].wagers.length;i++) {
            if(eventDB[eventID].wagers[i].won){
                totalPool += eventDB[eventID].wagers[i].amount;
            }
        }
        return totalPool;
    }

    function getEventWinningWagerPool(uint eventID) public view returns(uint) {
        return getEventTotalLosersWagerPool(eventID) - getEventWinningWarriorPool(eventID);
    }

    function getEventWinningWarriorPool(uint eventID) public view returns(uint) {
        return getEventTotalLosersWagerPool(eventID)/WINNING_WARRIOR_DIVISOR;
    }

    function winnersCalculated(uint eventID) public view returns(bool) {
        return eventDB[eventID].winnersCalculated;
    }
    
    function winnersPaid(uint eventID) public view returns(bool) {
        return eventDB[eventID].paid;
    }

    function getWinnerCount(uint eventID) public view returns(uint) {
        require(winnersCalculated(eventID),"!CALCULATED");
        return eventDB[eventID].winningWagers.length;
    }

    function getWinnerPortion(uint eventID) public view returns(uint) {
        return getEventWinningWagerPool(eventID) / getEventTotalWinnersWagerPool(eventID);
    }

    function getWinningWagerOwner(uint eventID, uint wagerIdx) public view returns(address payable) {
        require(winnersCalculated(eventID),"!CALCULATED");
        uint wagerID = eventDB[eventID].winningWagers[wagerIdx];
        return eventDB[eventID].wagers[wagerID].owner;
    }

    function getWinningWagerAmount(uint eventID, uint wagerIdx) public view returns(uint) {
        require(winnersCalculated(eventID),"!CALCULATED");
        uint wagerID = eventDB[eventID].winningWagers[wagerIdx];
        return eventDB[eventID].wagers[wagerID].amount;
    }

    function canCalculateWinners(uint eventID) public view returns(bool) {
        return(
            eventCore.getEventCount() >= eventID &&
            eventCore.getState(eventID) == EventCore.EventState.Finished &&
            !eventDB[eventID].winnersCalculated
        );
    }
    
    function canPayWinners(uint eventID) public view returns(bool) {
        return(
            eventCore.getEventCount() >= eventID &&
            eventCore.getState(eventID) == EventCore.EventState.Finished &&
            eventDB[eventID].winnersCalculated &&
            !eventDB[eventID].paid
        );
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Setters
    //////////////////////////////////////////////////////////////////////////////////////////
    
    function setEventCore(address payable core) public onlyOwner {
        eventCore = EventCore(core);
    }
    
    function setWarriorCore(address payable core) public onlyOwner {
        warriorCore = WarriorCore(core);
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Actions/Activities/Effects
    //////////////////////////////////////////////////////////////////////////////////////////

    function calculateWinners(uint eventID) public returns(uint) {
        require(canCalculateWinners(eventID),"!CANCALC");
        eventDB[eventID].winnersCalculated = true;
        uint winnerCount = 0;
        bool hasWinner = eventCore.hasWinner(eventID);
        if(hasWinner) {
            uint winnerID = eventCore.getWinner(eventID);
            for(uint i=0;i<eventDB[eventID].wagers.length;i++) {
                if(eventDB[eventID].wagers[i].warrior == winnerID){
                    eventDB[eventID].wagers[i].won = true;
                    eventDB[eventID].winningWagers.push(i);
                }
            }
            winnerCount = eventDB[eventID].winningWagers.length;
        }
        emit WinnersCalculated(msg.sender,eventID,winnerCount,hasWinner,uint32(block.timestamp));
        return winnerCount;
    }

    function payWinners(uint eventID) public {
        require(canPayWinners(eventID),"!CANPAY");
        eventDB[eventID].paid=true;
        uint donateAmount = 0;
        if(eventCore.hasWinner(eventID)) {
            uint winnerID = eventCore.getWinner(eventID);
		    warriorCore.payWarriorWithTax{value:getEventWinningWarriorPool(eventID)}(winnerID);
            emit WarriorPaid(winnerID,eventID,getEventWinningWarriorPool(eventID),uint32(block.timestamp));
        } else {
            donateAmount += getEventWinningWarriorPool(eventID);
        }
        uint winnerCount = getWinnerCount(eventID);
        if(winnerCount>0){
            uint winnerPortion = getWinnerPortion(eventID);
            for(uint i=0;i<eventDB[eventID].winningWagers.length;i++) {
                WagerData memory w = getWager(eventID,eventDB[eventID].winningWagers[i]);
                uint winnerAmount = (w.amount * winnerPortion) + w.amount;
                w.owner.transfer(winnerAmount);
                emit WinnerPaid(w.owner,eventID,winnerAmount,uint32(block.timestamp));
            }
        }else{
            donateAmount += getEventWinningWagerPool(eventID);
        }
        if(donateAmount>0) {
            eventCore.donate{value:donateAmount}();
            emit HouseDonation(eventID,donateAmount,uint32(block.timestamp));
        }
        emit PaymentTriggered(msg.sender,eventID,uint32(block.timestamp));
    }
}