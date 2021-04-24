// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.1;

import "./Utils.sol";
import "./WarriorCore.sol";
import "./LibWarrior.sol";
import "./WagerCore.sol";
import "./SponsorCore.sol";
import "./Random.sol";

contract EventCore is controlled,mortal,priced {
    uint constant minNewTime = 1 hours;
    uint constant minTimeBeforeCancel = 1 hours;
	uint constant idleTimeBeforeCancel = 24 hours;
	uint constant basePollGasAmount = 1800000;
	uint constant basePollGasPrice = 4 gwei;
	uint constant basePollCost = basePollGasAmount*basePollGasPrice;
	uint constant pollRewardPoolDivisor = 5; //Poll reward = 1/pollRewardPoolDivisor of total event pool (ie: if divisor is 5, then poll reward is 1/5 or 20%)
	uint32 constant minPollDuration = 30 seconds;

	uint8 constant absoluteMaxWarriors = 255;
	uint8 constant meleesPerPollPerWarrior = 1;
    uint8 constant exchangesPerMelee = 1;
    uint8 constant escapeThreshold = 2;
	
	uint8 constant escapeXPBase = 1;
	uint8 constant hitXPBase = 3;
	uint8 constant dodgeXPBase = 2;
	uint8 constant blockXPBase = 2;

	bool constant WAGERING_ENABLED = true;
	bool constant SPONSORS_ENABLED = true;

	uint public unclaimedPool = 0;

	enum EventState { New, Active, Finished }

	struct Event {
		address payable owner;
		//Storage Cell 1 End
		uint balance;
		//Storage Cell 2 End
		uint joinFee;
		//Storage Cell 3 End
		uint winner;
		//Storage Cell 4 End
		uint32 timeOpen;
		uint32 timeStart;
		uint32 blockStart;
		uint32 timeFinish;
		uint32 lastPollTime;
		uint32 newDuration;
		uint16 minLevel;
		uint16 maxLevel;
		uint16 minEquipLevel;
		uint16 maxEquipLevel;
		uint16 maxPolls;
		//Storage Cell 5 End
		uint8 warriorMin;
		uint8 warriorMax;
		bool winnerPresent;
		EventState state;
		//Variable Length Data:
		uint[] participants;
		address payable[] polls;
	}

    WarriorCore public warriorCore;
    WagerCore public wagerCore;
	SponsorCore public sponsorCore;
	Random public rng;

	Event[] events;
	mapping(uint=>mapping(uint=>bool)) eventParticipantsPresent;
	mapping(address=>uint) mrEvent;

    event EventCreated(
        uint32 indexed event_id,
        uint32 timeStamp,
		address indexed owner
        );
        
    event EventUnclaimedBonus(
        uint32 indexed event_id,
        uint32 timeStamp,
		uint amount
        );

    event EventHasUnclaimed(
        uint32 indexed event_id,
        uint32 timeStamp,
		uint amount
        );
	
    event EventStarted(
        uint32 indexed event_id,
        uint32 timeStamp
        );
        
    event EventFinished(
        uint32 indexed event_id,
        uint32 timeStamp
        );
        
    event EventCancelled(
        uint32 indexed event_id,
        uint32 timeStamp
        );
    
    event EventPolled(
        uint32 indexed event_id,
        uint32 timeStamp,
		uint32 indexed pollCount
        );
    
    event EventWinner(
        uint32 indexed event_id,
        uint64 indexed warrior,
        uint32 timeStamp
        );

    event WarriorJoinedEvent(
        uint32 indexed event_id,
        uint64 indexed warrior,
        uint32 timeStamp
        );
    
    event WarriorDefeated(
        uint32 indexed event_id,
        uint64 indexed warrior,
        uint64 indexed attacker,
        uint16 warriorLevel,
        uint16 attackerLevel,
        uint32 timeStamp
        ); 
        
    event WarriorEngaged(
        uint32 indexed event_id,
        uint64 indexed warriorA,
        uint64 indexed warriorB,
        uint32 timeStamp
        );

    event WarriorEscaped(
        uint32 indexed event_id,
        uint64 indexed warrior,
        uint64 indexed attacker,
        uint32 timeStamp
        );
        
    event WarriorDrankPotion(
        uint32 indexed event_id,
        uint64 indexed warrior,
        uint64 indexed attacker,
        uint32 timeStamp
        );
        
    event WarriorHit(
        uint32 indexed event_id,
        uint64 indexed warrior,
        uint64 indexed attacker,
        uint32 damageDealt,
        uint32 timeStamp
        );

    event WarriorDodged(
        uint32 indexed event_id,
        uint64 indexed warrior,
        uint64 indexed attacker,
        uint32 timeStamp
        );

    event WarriorBlocked(
        uint32 indexed event_id,
        uint64 indexed warrior,
        uint64 indexed attacker,
        uint32 damageBlocked,
        uint32 timeStamp
        );

	event EquipmentWorn(
        uint32 indexed event_id,
        uint64 indexed warrior,
        uint8 indexed equipment,
		uint32 result,
        uint32 timeStamp
		);

	event Donation(
		address indexed sender,
		uint amount,
		uint32 timeStamp
		);

	modifier onlyEventState(uint eventID, EventState state) {
		require(events[eventID].state == state,"!STATE");
		_;
	}

	modifier onlyEventOwner(uint eventID) {
		require(msg.sender == events[eventID].owner,"!OWNER");
		_;
	}

	modifier onlyTrustedWarriors() {
		//Check that the message came from the trusted WarriorCore from BattleDromeCore
		require(msg.sender == address(warriorCore),"!TRUST");
		_;
	}

    function setWarriorCore(address core) public onlyOwner {
        warriorCore = WarriorCore(core);
    }

    function setWagerCore(address core) public onlyOwner {
        wagerCore = WagerCore(core);
    }
    
	function setSponsorCore(address core) public onlyOwner {
        sponsorCore = SponsorCore(core);
    }

	function setRNG(address payable rngContract) public onlyOwner{
		rng = Random(rngContract);
	}

	function getNewEventFee(uint _warriorCount, uint _pollCount) public pure returns(uint) {
		return basePollCost * (_warriorCount+1) * (_pollCount+1) * 5 / 4; // 5/4 = 1.25 for 25% contingency margin
	}

	function getWagerStatus() public pure returns(bool) {
		return WAGERING_ENABLED;
	}

	function getSponsorStatus() public pure returns(bool) {
		return SPONSORS_ENABLED;
	}

	function hasCurrentEvent(address owner) public view returns(bool) {
		return mrEvent[owner] != 0 && events[mrEvent[owner]].state != EventState.Finished;
	}

	function canCreateEvent(uint8 warriorMax) public view returns(bool) {
		return warriorMax<=absoluteMaxWarriors && (events.length==0 || !hasCurrentEvent(msg.sender));
	}

	function newEvent(uint8 _warriorMin, uint8 _warriorMax, uint16 _minLevel, uint16 _maxLevel, uint16 _minEquipLevel, uint16 _maxEquipLevel, uint16 _maxPolls, uint _joinFee) public payable costsWithExcess(getNewEventFee(_warriorMax,_maxPolls)) returns(uint theNewEvent) {
		require(canCreateEvent(_warriorMax),"!CREATE");

		//Calculate Durations based on participants
		uint32 timeBase = 1 hours * _minLevel * _warriorMin;

		//Add a newly created warrior to the warriors array
		events.push(Event(
			payable(msg.sender),	//owner
			msg.value,				//balance
			_joinFee,				//joinFee
			0,						//winner
			uint32(block.timestamp),//timeOpen
			0,						//timeStart
			0,						//blockStart
			0,						//timeFinish
			0,						//lastPollTime
			timeBase,				//newDuration
			_minLevel,				//minLevel
			_maxLevel,				//maxLevel
			_minEquipLevel,			//minEquipLevel
			_maxEquipLevel,			//maxEquipLevel
			_maxPolls,				//maxPolls
			_warriorMin,			//warriorMin
			_warriorMax,			//warriorMax
			false,					//winnerPresent
			EventState.New,			//state
			new uint[](0),			//participants
			new address payable[](0)//polls
		));
		//Calculate Unclaimed Contribution
		getUnclaimedContribution(events.length-1);
		//Emit Event
		emit EventCreated(uint32(events.length-1),uint32(block.timestamp),msg.sender);
		//Mark new most recent event for this owner:
		mrEvent[msg.sender] = events.length-1;
		//Return new event index
		return events.length-1;
	}

	function getUnclaimedContribution(uint eventID) internal {
		Event storage e = events[eventID];
		uint eventFee = getNewEventFee(e.warriorMax,e.maxPolls);
		uint unclaimedAmount;
		if(unclaimedPool>eventFee){
			unclaimedAmount = eventFee;
		}else{
			unclaimedAmount = unclaimedPool;
		}
		if(unclaimedAmount>0){
			unclaimedPool -= unclaimedAmount;
			e.balance += unclaimedAmount;
			emit EventUnclaimedBonus(uint32(eventID),uint32(block.timestamp),unclaimedAmount);
		}
	}

	function getEventCount() public view returns(uint) {
		return events.length;
	}

	function transferOwnership(uint theEvent, address payable newOwner) public onlyEventOwner(theEvent) {
		events[theEvent].owner = newOwner;
	}

	function getOwner(uint eventID) public view returns(address payable) {
		return events[eventID].owner;
	}

	function getWinnerRewardPool(uint eventID) public view returns(uint) {
		return events[eventID].balance-getPollRewardPool(eventID);
	}

	function getPollRewardPool(uint eventID) public view returns(uint) {
		return getCurrentRewardPerPoll(eventID)*getPollCount(eventID);
	}

	function getCurrentRewardPerPoll(uint eventID) public view returns(uint) {
		return events[eventID].balance/(getPollCount(eventID)*pollRewardPoolDivisor);
	}
	
	function getBalance(uint eventID) public view returns(uint) {
		return events[eventID].balance;
	}

	function getWinner(uint eventID) public view returns(uint) {
		return events[eventID].winner;
	}

	function getPollCount(uint eventID) public view returns(uint32) {
		return uint32(events[eventID].polls.length);
	}

	function getPoller(uint eventID, uint idx) public view returns(address) {
		return events[eventID].polls[idx];
	}

	function getLastPoll(uint eventID) public view returns(address) {
		if(events[eventID].polls.length>0){
			return events[eventID].polls[events[eventID].polls.length-1];
		}else{
			return address(0);
		}
	}

	function getTimeOpen(uint eventID) public view returns(uint32) {
		return events[eventID].timeOpen;
	}

	function getTimeStart(uint eventID) public view returns(uint32) {
		return events[eventID].timeStart;
	}

	function getBlockStart(uint eventID) public view returns(uint32) {
		return events[eventID].blockStart;
	}

	function getTimeFinish(uint eventID) public view returns(uint32) {
		return events[eventID].timeFinish;
	}

	function getNewDuration(uint eventID) public view returns(uint32) {
		return events[eventID].newDuration;
	}

	function getMinLevel(uint eventID) public view returns(uint16) {
		return events[eventID].minLevel;
	}

	function getMaxLevel(uint eventID) public view returns(uint16) {
		return events[eventID].maxLevel;
	}

	function getMinEquipLevel(uint eventID) public view returns(uint16) {
		return events[eventID].minEquipLevel;
	}

	function getMaxEquipLevel(uint eventID) public view returns(uint16) {
		return events[eventID].maxEquipLevel;
	}

	function getMaxPolls(uint eventID) public view returns(uint16) {
		return events[eventID].maxPolls;
	}
	
	function getWarriorMin(uint eventID) public view returns(uint8) {
		return events[eventID].warriorMin;
	}

	function getWarriorMax(uint eventID) public view returns(uint8) {
		return events[eventID].warriorMax;
	}

	function getState(uint eventID) public view returns(EventState) {
		return events[eventID].state;
	}

	function getJoinFee(uint eventID) public view returns(uint) {
		return events[eventID].joinFee;
	}

	function getParticipantCount(uint eventID) public view returns(uint8) {
		return uint8(events[eventID].participants.length);
	}

	function getParticipant(uint eventID, uint idx) public view returns(uint) {
		return events[eventID].participants[idx];
	}

	function canAddParticipant(uint eventID, uint level) public view returns(bool) {
		return (
			level >= events[eventID].minLevel &&
			level <= events[eventID].maxLevel &&
			events[eventID].participants.length < events[eventID].warriorMax &&
			events[eventID].state == EventState.New
		);
	}

	function canParticipate(uint eventID, uint newWarrior) public view returns(bool) {
		return (
			(warriorCore.getState(newWarrior)==LibWarrior.warriorState.Idle)
			&& eventParticipantsPresent[eventID][newWarrior] == false
			&& canAddParticipant(eventID, warriorCore.getLevel(newWarrior))
			&& (warriorCore.getEquipLevel(newWarrior)>=getMinEquipLevel(eventID))
		);
	}

	function checkParticipation(uint eventID, uint theWarrior) public view returns(bool) {
		return eventParticipantsPresent[eventID][theWarrior];
	}

	function canStart(uint eventID) public view returns(bool) {
		return (
			block.timestamp - events[eventID].timeOpen > events[eventID].newDuration && 
			events[eventID].participants.length >= events[eventID].warriorMin
		);
	}	

	function canCancel(uint eventID) public view returns(bool) {
		return (
			(
				msg.sender == getOwner(eventID) &&
				block.timestamp - events[eventID].timeOpen > minTimeBeforeCancel && 
				events[eventID].participants.length < events[eventID].warriorMin &&
				events[eventID].state == EventState.New
			) || (
				events[eventID].state == EventState.Active &&
				getTimeSinceLastPoll(eventID) > idleTimeBeforeCancel
			)
		);
	}	

	function hasWinner(uint eventID) public view returns(bool) {
		return events[eventID].winnerPresent;
	}

	function isStalemate(uint eventID) public view returns(bool) {
        return (
            !hasWinner(eventID) &&
            (getPollCount(eventID) >= getMaxPolls(eventID))
        );
	}

	function setStartTime(uint eventID, uint32 _timeStart) internal {
		events[eventID].timeStart = _timeStart;
	}

	function setStartBlock(uint eventID, uint32 _blockStart) internal {
		events[eventID].blockStart = _blockStart;
	}

	function setFinishTime(uint eventID, uint32 _timeFinish) internal {
		events[eventID].timeFinish = _timeFinish;
	}

	function setState(uint eventID, EventState _state) internal {
		events[eventID].state = _state;
	}

	function joinEvent(uint eventID, uint theWarrior) public payable onlyTrustedWarriors() costs(getJoinFee(eventID)) {
		//Is this warrior allowed to join?
        require(canParticipate(eventID,theWarrior),"!PARTICIPATE");
		events[eventID].participants.push(theWarrior);
		eventParticipantsPresent[eventID][theWarrior] = true;
		events[eventID].balance += msg.value;
		emit WarriorJoinedEvent(uint32(eventID),uint64(theWarrior),uint32(block.timestamp));
	}

	function setWinner(uint eventID, uint theWinner) internal {
		events[eventID].winner = theWinner;
		events[eventID].winnerPresent = true;
	}

    function start(uint eventID) public onlyEventState(eventID,EventState.New) {
        require(canStart(eventID),"!START");
        setStartTime(eventID,uint32(block.timestamp));
        setStartBlock(eventID,uint32(block.number));
		setState(eventID,EventState.Active);
        for(uint p=0;p<events[eventID].participants.length;p++) {
			warriorCore.beginBattle(events[eventID].participants[p]);
		}
        emit EventStarted(uint32(eventID),uint32(block.timestamp));
		triggerSponsorCalculation(eventID);
    }

    function cancel(uint eventID) public {
        require(canCancel(eventID),"!CANCEL");
        events[eventID].state = EventState.Finished;
        setFinishTime(eventID,uint32(block.timestamp));
		for(uint p=0;p<events[eventID].participants.length;p++) {
			//Refund any fees paid by warrior
			warriorCore.payWarrior{value:events[eventID].joinFee}(events[eventID].participants[p]);
			//Remove the warrior from the event, freeing them
			warriorCore.endBattle(events[eventID].participants[p]);
		}
		//Send any remaining event balance back to the event owner
		events[eventID].owner.transfer(getBalance(eventID));
        emit EventCancelled(uint32(eventID),uint32(block.timestamp));
    }

    function finish(uint eventID) internal {
        setState(eventID,EventState.Finished);
        setFinishTime(eventID,uint32(block.timestamp));
		for(uint p=0;p<events[eventID].participants.length;p++) {
			warriorCore.endBattle(events[eventID].participants[p]);
		}
        emit EventFinished(uint32(eventID),uint32(block.timestamp));
		payPollRewards(eventID);
		payWinnerRewards(eventID);
		triggerSponsorPayout(eventID);
    }

	function triggerSponsorCalculation(uint eventID) internal {
		if(SPONSORS_ENABLED) sponsorCore.calculateWinners(eventID);
	}

	function triggerSponsorPayout(uint eventID) internal {
		if(SPONSORS_ENABLED) sponsorCore.paySponsorship(eventID);		
	}

	function payWarrior(uint eventID, uint amount, uint warriorID) internal {
		require(events[eventID].balance>=amount,"BALANCE");
		events[eventID].balance -= amount;
		warriorCore.payWarrior{value:amount}(warriorID);
	}

	function payPlayer(uint eventID, uint amount, address payable player) internal {
		require(events[eventID].balance>=amount,"BALANCE");
		events[eventID].balance -= amount;
		player.transfer(amount);
	}

	function payPollRewards(uint eventID) internal {
		uint pollReward = getCurrentRewardPerPoll(eventID);
		for(uint pollNum=0;pollNum<getPollCount(eventID);pollNum++){
			payPlayer(eventID,pollReward,events[eventID].polls[pollNum]);
		}
	}
	
	function payWinnerRewards(uint eventID) internal {
		uint rewardToPay = getBalance(eventID); //TODO: Fix this later, not important for beta.
		if(hasWinner(eventID)){
			payWarrior(eventID,rewardToPay,getWinner(eventID));
		}else{
			unclaimedWinnerRewards(eventID,rewardToPay);
		}
	}

	function getUnclaimedPool() public view returns (uint) {
		return unclaimedPool;
	}

	function unclaimedWinnerRewards(uint eventID, uint amount) internal {
		require(getBalance(eventID)>=amount,"BALANCE");
		events[eventID].balance -= amount;
		unclaimedPool += amount;
		emit EventHasUnclaimed(uint32(eventID),uint32(block.timestamp),amount);
	}

	function donate() public payable {
		unclaimedPool += msg.value;
		emit Donation(msg.sender,msg.value,uint32(block.timestamp));
	}

	function getTimeSinceLastPoll(uint eventID) public view returns (uint) {
		if(getState(eventID)==EventState.New){
			return block.timestamp - events[eventID].timeOpen;
		}else if(getPollCount(eventID)>0){
			return block.timestamp - events[eventID].lastPollTime;
		}else{
			return block.timestamp - events[eventID].timeStart;
		}
	}

	function canPoll(uint eventID) public view returns (bool) {
		//Can't poll if either event in wrong state, or if you were the last poller.
		//Also can't poll more than once per `minPollDuration`
		return events[eventID].state == EventState.Active && getLastPoll(eventID) != msg.sender && getTimeSinceLastPoll(eventID) >= minPollDuration;
	}

	function poll(uint eventID) public {
		require(canPoll(eventID),"!POLL");
		events[eventID].polls.push(payable(msg.sender));
		for(uint melee=0;melee<getParticipantCount(eventID)*meleesPerPollPerWarrior;melee++) {
			uint8 wCount = getParticipantCount(eventID);
			uint8 r1 = rng.getRandomUint8();
			uint8 r2 = rng.getRandomUint8();
			uint8 warriorIdxA = r1 % wCount;
			uint8 warriorIdxB = r2 % (wCount-1);
			if(warriorIdxB>=warriorIdxA) warriorIdxB++;
			uint a = getParticipant(eventID,warriorIdxA);
			uint b = getParticipant(eventID,warriorIdxB);
			if(resolveMelee(eventID,a,b)) {
				if(checkForWinner(eventID)){
					finish(eventID);
					return;
				}
			}
		}
		if(isStalemate(eventID) || hasWinner(eventID)){
			finish(eventID);
		} 
		emit EventPolled(uint32(eventID),uint32(block.timestamp),getPollCount(eventID));
	}

    function resolveMelee(uint eventID, uint a, uint b) internal returns (bool) {
		require(a!=b,"!MELEESELF");
		emit WarriorEngaged(uint32(eventID),uint64(a),uint64(b),uint32(block.timestamp));
		//Check for First Strike:
		if(warriorCore.getWeaponClass(a)==LibWarrior.WeaponClass.ExtRange && warriorCore.getWeaponClass(b)!=LibWarrior.WeaponClass.ExtRange) {
			//A Gets First Strike
			if(resolveAttack(eventID,a,b)) return true;
		} else if(warriorCore.getWeaponClass(b)==LibWarrior.WeaponClass.ExtRange && warriorCore.getWeaponClass(a)!=LibWarrior.WeaponClass.ExtRange) {
			//B Gets First Strike
			if(resolveAttack(eventID,b,a)) return true;
		}
		//No Remaining Advantage, continue with normal Melee Process:
        for(uint8 exchange=0;exchange<exchangesPerMelee;exchange++) {
            if(handleEscape(eventID,a,b)) return false;
            if(resolveAttack(eventID,a,b)) return true;
            if(resolveAttack(eventID,b,a)) return true;
        }
        return false;
    }

    function handleDefeat(uint eventID, uint attacker, uint defender) internal {
        warriorCore.sendLoot(defender,attacker);
        warriorCore.earnXPForKill(attacker,warriorCore.getLevel(defender));
        removeParticipant(eventID,defender);
        warriorCore.kill(defender);
        emit WarriorDefeated(uint32(eventID),uint64(defender),uint64(attacker),uint16(warriorCore.getLevel(defender)),uint16(warriorCore.getLevel(attacker)),uint32(block.timestamp));
    }

    function checkForWinner(uint eventID) internal returns(bool) {
        if(getParticipantCount(eventID)==1){
            setWinner(eventID,getParticipant(eventID,0));
            emit EventWinner(uint32(eventID),uint64(getParticipant(eventID,0)),uint32(block.timestamp));
            return true;
        }
        return false;
    }

    function handleEscape(uint eventID, uint a, uint b) internal returns(bool) {
        if(warriorCore.getLevel(a) > warriorCore.getLevel(b) + escapeThreshold) return attemptEscape(eventID,b,a);
        if(warriorCore.getLevel(b) > warriorCore.getLevel(a) + escapeThreshold) return attemptEscape(eventID,a,b);
		return false; //If the comparison ends up equal for any reason, the fallback position is that neither can escape.
    }

    function attemptEscape(uint eventID, uint escapee, uint opponent) internal returns(bool) {
		bool escaped = warriorCore.rollEscape(escapee) > warriorCore.getDex(opponent);
		if(escaped) {
			warriorCore.awardXP(escapee,uint64(escapeXPBase*warriorCore.getLevel(escapee)));
			emit WarriorEscaped(uint32(eventID),uint64(escapee),uint64(opponent),uint32(block.timestamp));
		} 
        return escaped;
	}

    function resolveAttack(uint eventID, uint attacker, uint defender) internal returns(bool defenderDeath) {
		//BUG HERE
		//////////////////////////////////////////////
        uint hitRoll = warriorCore.rollHit(attacker);
		//////////////////////////////////////////////
		uint dodgeRoll = warriorCore.rollDodge(defender); //Actually bug is in the final assignment here
		uint blockRoll = 0;
		int dmg = 0;
		uint dmgReduction = 0;
		if(hitRoll > dodgeRoll) {
			if(warriorCore.getShieldType(defender)!=LibWarrior.ShieldType.None && warriorCore.getShield(defender)>0) {
				//Defender has a shield, so has opportunity to block:
				//Bludgeoning Weapons can't be blocked by light or medium shields.
				if(warriorCore.getWeaponClass(attacker)!=LibWarrior.WeaponClass.Bludgeoning || warriorCore.getShieldType(defender)==LibWarrior.ShieldType.Heavy) {
					blockRoll = warriorCore.rollBlock(defender);
				}
			}
			dmg = warriorCore.rollDamage(attacker);
			if(hitRoll>blockRoll){
				//Hit was not blocked!
				dmgReduction = warriorCore.getDamageReduction(defender);
				if(warriorCore.getWeaponClass(attacker)==LibWarrior.WeaponClass.Cleaving || warriorCore.getWeaponClass(attacker)==LibWarrior.WeaponClass.Bludgeoning) {
					//Heavy Weapons Bypass some damage reduction
					dmgReduction = dmgReduction/2;
				}
				//Attacker Successfully hit their target!
				warriorCore.awardXP(attacker,uint64(hitXPBase*warriorCore.getLevel(attacker)));
				dmg -= int(dmgReduction);
				if(dmg>0){
					//Warrior was hit and received damage!
					emit WarriorHit(uint32(eventID),uint64(defender),uint64(attacker),uint32(uint256(dmg)),uint32(block.timestamp));
					warriorCore.wearWeapon(attacker);
					emit EquipmentWorn(uint32(eventID),uint64(attacker),uint8(0),uint32(warriorCore.getWeapon(attacker)),uint32(block.timestamp));
					warriorCore.wearArmor(defender);
					emit EquipmentWorn(uint32(eventID),uint64(defender),uint8(2),uint32(warriorCore.getArmor(defender)),uint32(block.timestamp));
					if(warriorCore.applyDamage(defender,uint64(uint256(dmg)))) {
						//Applied damage would result in death
						if(warriorCore.getPotions(defender)>0) {
							//Warrior had potions, auto-heal to keep warrior alive!
							warriorCore.autoPotion(defender);
							emit WarriorDrankPotion(uint32(eventID),uint64(defender),uint64(attacker),uint32(block.timestamp));
						} else {
							//No potions, warrior defeated
							handleDefeat(eventID,attacker,defender);
							return true;
						}
					}
				}else{
					//Damage was nullified. But warrior was still hit
					emit WarriorHit(uint32(eventID),uint64(defender),uint64(attacker),0,uint32(block.timestamp));
				}
			}else{
				//Hit was Blocked!
				warriorCore.awardXP(defender,uint64(blockXPBase*warriorCore.getLevel(defender)));
				emit WarriorBlocked(uint32(eventID),uint64(defender),uint64(attacker),uint32(uint256(dmg)),uint32(block.timestamp));
				//Block still causes wear to weapon, and to shield
				warriorCore.wearWeapon(attacker);
				emit EquipmentWorn(uint32(eventID),uint64(attacker),uint8(0),uint32(warriorCore.getWeapon(attacker)),uint32(block.timestamp));
				warriorCore.wearShield(defender);
				emit EquipmentWorn(uint32(eventID),uint64(defender),uint8(1),uint32(warriorCore.getShield(defender)),uint32(block.timestamp));
			}
        } else {
			//Warrior Dodged The Attack!
			warriorCore.awardXP(defender,uint64(dodgeXPBase*warriorCore.getLevel(defender)));
			emit WarriorDodged(uint32(eventID),uint64(defender),uint64(attacker),uint32(block.timestamp));
		}
        return false;
    }

    function removeParticipant(uint eventID, uint removed) internal {
        for(uint i=0;i<getParticipantCount(eventID);i++) {
            if(events[eventID].participants[i]==removed) {
                events[eventID].participants[i] = events[eventID].participants[getParticipantCount(eventID)-1];
                events[eventID].participants.pop();
                return;
            }
        }
		revert("!NotFound");
    }

}
