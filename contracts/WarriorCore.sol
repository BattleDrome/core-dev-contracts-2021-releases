// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.1;

import "./Utils.sol";
import "./LibWarrior.sol";
import "./Random.sol";

contract WarriorCore is owned,simpleTransferrable,controlled,mortal,priced {

    using LibWarrior for warrior;

    //////////////////////////////////////////////////////////////////////////////////////////
    // Config
    //////////////////////////////////////////////////////////////////////////////////////////

    //Costing Config

    uint constant warriorCost = 10000000 gwei;
    uint constant potionCost = 10000000 gwei;
    uint constant intPotionCost = 50000000 gwei;
   
    //Misc Config
    uint32 constant cashoutDelay = 24 hours;    
    uint8 constant luckMultiplier = 2;
    uint16 constant wearPercentage = 10;

    //////////////////////////////////////////////////////////////////////////////////////////
    // State
    //////////////////////////////////////////////////////////////////////////////////////////

	struct AccountData {
		uint[] warriors;
	}

    Random rng;

	mapping(address=>AccountData) warriorMapping;
	mapping(string=>bool) warriorNames;
	mapping(string=>uint) warriorsByName;
    mapping(uint=>uint) trainerMapping;
    mapping(address=>bool) trustedContracts;

	warrior[] warriors;
    uint[] warriorMarket;
    uint[] trainerMarket;

    //////////////////////////////////////////////////////////////////////////////////////////
    // Modifiers
    //////////////////////////////////////////////////////////////////////////////////////////

	modifier onlyTrustedContracts() {
		//Check that the message came from a Trusted Contract
		require(trustedContracts[msg.sender]);
		_;
	}

	modifier onlyState(uint warriorID, warriorState state) {
		require(warriors[warriorID].state == state);
		_;
	}

	modifier costsPoints(uint warriorID, uint _points) {
        require(warriors[warriorID].stats.points >= uint64(_points));
        warriors[warriorID].stats.points -= uint64(_points);
        _;
    }

    modifier costsPassThrough(uint _amount, uint warriorID) {
        require(msg.value >= _amount);
        _;
        if (msg.value > _amount) payable(msg.sender).transfer(msg.value - _amount);
        warriors[warriorID].receiveFunds(_amount,false);
    }

    modifier costsPassThroughTax(uint _amount, uint warriorID) {
        require(msg.value >= _amount);
        _;
        if (msg.value > _amount) payable(msg.sender).transfer(msg.value - _amount);
        warriors[warriorID].receiveFunds(_amount,true);
    }

	modifier onlyWarriorOwner(uint warriorID) {
		require(msg.sender == warriors[warriorID].owner);
		_;
	}

	modifier onlyDoneTraining(uint warriorID) {
        require(block.timestamp >= warriors[warriorID].trainingEnds);
        _;
    }

    modifier onlyAfter(uint warriorID, uint _time) {
        require(block.timestamp >= warriors[warriorID].creationTime + _time);
        _;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Events
    //////////////////////////////////////////////////////////////////////////////////////////

    event WarriorCreated(
        address indexed creator,
        uint64 indexed warrior,
        uint32 timeStamp
        );

    event WarriorAltered(
        uint64 indexed warrior,
        uint32 timeStamp
        );
    
    event WarriorLevelled(
        uint64 indexed warrior,
        uint32 timeStamp
        );

    event WarriorRetired(
        uint64 indexed warrior,
        uint indexed balance,
        uint32 timeStamp
        );

    event WarriorRevived(
        uint64 indexed warrior,
        uint32 timeStamp
        );
    
    event WarriorDrankPotion(
        uint64 indexed warrior,
        uint32 timeStamp
        );

    event WarriorTraining(
        uint64 indexed warrior,
        uint32 timeStamp
        );
    
    event WarriorDoneTraining(
        uint64 indexed warrior,
        uint32 timeStamp
        );

    event NewTrainer(
        uint64 indexed warrior,
        uint indexed fee,
        uint32 timeStamp
        );
    
    event TrainerStopped(
        uint64 indexed warrior,
        uint32 timeStamp
        );

    //////////////////////////////////////////////////////////////////////////////////////////
    // Warrior Constructor
    //////////////////////////////////////////////////////////////////////////////////////////

	function newWarrior(address payable warriorOwner, uint16 colorHue, uint8 armorType, uint8 shieldType, uint8 weaponType) public payable costs(warriorCost) returns(uint theNewWarrior) {
        //Generate a new random seed for the warrior
        uint randomSeed = rng.getRandomUint256();
		//Generate a new warrior, and add it to the warriors array
		warriors.push(LibWarrior.newWarrior(warriorOwner,randomSeed,colorHue,ArmorType(armorType),ShieldType(shieldType),WeaponType(weaponType)));
		//Add the warrior to the appropriate owner index
		addWarriorToOwner(warriorOwner,warriors.length-1);
		//Pay the warrior the fee
        warriors[warriors.length-1].receiveFunds(warriorCost,false);
        //Fire the event
        emit WarriorCreated(warriorOwner,uint64(warriors.length-1),uint32(block.timestamp));
		//Return new warrior index
		return warriors.length-1;
	}

    //////////////////////////////////////////////////////////////////////////////////////////
    // Collection Management
    //////////////////////////////////////////////////////////////////////////////////////////

	function getGlobalWarriorCount() public view returns(uint) {
		return warriors.length;
	}

	function getWarriorID(address warriorOwner, uint warriorNumber) public view returns(uint) {
		return warriorMapping[warriorOwner].warriors[warriorNumber];
	}

	function getWarriorIDByName(string memory name) public view returns(uint) {
		return warriorsByName[name];
	}

	function getWarriorCount(address warriorOwner) public view returns(uint) {
		return warriorMapping[warriorOwner].warriors.length;
	}

	function removeWarriorFromOwner(address warriorOwner, uint theWarrior) internal {
        for(uint i=0;i<warriorMapping[warriorOwner].warriors.length;i++) {
            if(warriorMapping[warriorOwner].warriors[i]==theWarrior) {
				warriorMapping[warriorOwner].warriors[i] = warriorMapping[warriorOwner].warriors[warriorMapping[warriorOwner].warriors.length-1];
				warriorMapping[warriorOwner].warriors.pop();
                return;
            }
        }
	}

	function addWarriorToOwner(address warriorOwner, uint theWarrior) internal {
		warriorMapping[warriorOwner].warriors.push(theWarrior);
	}

    function nameExists(string memory _name) public view returns(bool) {
        return warriorNames[_name] == true;
    }

	function transferOwnershipInternal(uint warriorID, address oldOwner, address payable newOwner) internal {
		removeWarriorFromOwner(oldOwner,warriorID);
		addWarriorToOwner(newOwner,warriorID);
        warriors[warriorID].setOwner(newOwner);
	}

	function transferOwnership(uint warriorID, address payable oldOwner, address payable newOwner) public onlyWarriorOwner(warriorID) {
        transferOwnershipInternal(warriorID,oldOwner,newOwner);
	}

	function addTrainerToMarket(uint theWarrior) internal {
		trainerMarket.push(theWarrior);
	}

	function removeTrainerFromMarket(uint theWarrior) internal {
        if(trainerMarket.length==1) {
            delete trainerMarket;
        }else{
            for(uint i=0;i<trainerMarket.length;i++) {
                if(trainerMarket[i]==theWarrior) {
                    trainerMarket[i] = trainerMarket[trainerMarket.length-1];
                    trainerMarket.pop();
                    return;
                }
            }
        }
	}

    function getTrainerMarketCount() public view returns (uint) {
        return trainerMarket.length;
    }

    function getTrainerIDFromMarket(uint index) public view returns (uint) {
        return trainerMarket[index];
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Basic Getters
    //////////////////////////////////////////////////////////////////////////////////////////

    function getWarriorCost() public pure returns(uint) {
        return warriorCost;
    }

    function getWarrior(uint warriorID) public view returns(warrior memory) {
        return warriors[warriorID];
    }

    function getWarriorStats(uint warriorID) public view returns(warriorStats memory) {
        return warriors[warriorID].stats;
    }

    function getWarriorEquipment(uint warriorID) public view returns(warriorEquipment memory) {
        return warriors[warriorID].equipment;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Derivation / Calaculation Pure Functions
    //////////////////////////////////////////////////////////////////////////////////////////

    function calcXPTargetForLevel(uint16 level) public pure returns(uint) {        
        return LibWarrior.calcXPTargetForLevel(level);
    }

    function calcXPForPractice(uint16 level) public pure returns (uint) {
        return LibWarrior.calcXPForPractice(level);
    }

    function calcDominantStatValue(uint16 con, uint16 dex, uint16 str) public pure returns(uint) {
        return LibWarrior.calcDominantStatValue(con,dex,str);
    }

    function calcTimeToPractice(uint16 level) public pure returns(uint) {
		return LibWarrior.calcTimeToPractice(level);
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Derived/Calculated Getters
    //////////////////////////////////////////////////////////////////////////////////////////

    function getName(uint warriorID) public view returns(string memory) {
        return warriors[warriorID].getName();
    }

    function canRevive(uint warriorID) public view returns(bool) {
        return warriors[warriorID].canRevive();
    }

    function getLuckFactor(uint warriorID) internal returns (uint) {
        return rng.getRandomRange24(0,warriors[warriorID].stats.luck*luckMultiplier);
    }

    function getCosmeticProperty(uint warriorID, uint propertyIndex) public view returns (uint48) {
        return uint48(warriors[warriorID].getCosmeticProperty(propertyIndex));
    }

    function getWeaponClass(uint warriorID) public view returns(WeaponClass) {
        return warriors[warriorID].getWeaponClass();
    }

    function getReviveCost(uint warriorID) public view returns(uint) {
        return LibWarrior.calcReviveCost(warriors[warriorID].stats.level);
    }
    
    function canTrainWith(uint warriorID, uint trainerID) public view returns(bool) {
        return warriors[warriorID].canTrainWith(warriors[trainerID]);
    }

    function getEquipLevel(uint warriorID) public view returns(uint) {
        return uint256(warriors[warriorID].getWeaponClass());
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Costing Getters
    //////////////////////////////////////////////////////////////////////////////////////////

    function getStatsCost(uint warriorID, uint8 strAmount, uint8 dexAmount, uint8 conAmount, uint8 luckAmount) public view returns (uint) {
        return warriors[warriorID].getStatsCost(strAmount,dexAmount,conAmount,luckAmount);
    }

    function getEquipCost(uint warriorID, uint8 armorAmount, uint8 shieldAmount, uint8 weaponAmount, uint8 potionAmount, uint8 intPotionAmount) public view returns(uint) {
        return warriors[warriorID].getEquipCost(armorAmount,shieldAmount,weaponAmount,potionAmount,intPotionAmount);
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Setters
    //////////////////////////////////////////////////////////////////////////////////////////

    function setName(uint warriorID, string memory name) public onlyWarriorOwner(warriorID) {
		//Check if the name is unique
		require(!nameExists(name));
        //Set the name
        warriors[warriorID].setName(name);
        //Add warrior's name to index
        warriorNames[name] = true;
        warriorsByName[name] = warriorID;
        touch(warriorID);
    }

    function addTrustedContract(address trustee) public onlyOwner {
        trustedContracts[trustee] = true;
    }

    function removeTrustedContract(address trustee) public onlyOwner {
        trustedContracts[trustee] = false;
    }

    function setRNG(address rngContract) public onlyOwner {
        rng = Random(rngContract);
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Buying Things
    //////////////////////////////////////////////////////////////////////////////////////////

    function buyStats(uint warriorID, uint8 strAmount, uint8 dexAmount, uint8 conAmount, uint8 luckAmount) public onlyWarriorOwner(warriorID) onlyState(warriorID,warriorState.Idle) costsPoints(warriorID,warriors[warriorID].getStatsCost(strAmount,dexAmount,conAmount,luckAmount)) {
        warriors[warriorID].buyStats(strAmount,dexAmount,conAmount,luckAmount);
        touch(warriorID);
    }

    function buyEquipment(uint warriorID, uint8 armorAmount, uint8 shieldAmount, uint8 weaponAmount, uint8 potionAmount, uint8 intPotionAmount) public payable costsPassThrough(warriors[warriorID].getEquipCost(armorAmount,shieldAmount,weaponAmount,potionAmount,intPotionAmount),warriorID) onlyState(warriorID, warriorState.Idle) {
        warriors[warriorID].buyEquipment(armorAmount,shieldAmount,weaponAmount,potionAmount,intPotionAmount);
        touch(warriorID);
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Transaction/Payment Handling
    //////////////////////////////////////////////////////////////////////////////////////////

	function payWarrior(uint warriorID) payable public {
        warriors[warriorID].receiveFunds(msg.value,false);
        touch(warriorID);
	}

	function payWarriorWithTax(uint warriorID) payable public {
        warriors[warriorID].receiveFunds(msg.value,true);
        touch(warriorID);
	}

    //////////////////////////////////////////////////////////////////////////////////////////
    // Actions/Activities/Effects
    //////////////////////////////////////////////////////////////////////////////////////////

    function touch(uint warriorID) internal {
        emit WarriorAltered(uint64(warriorID),uint32(block.timestamp));
    }

	function awardXP(uint warriorID, uint64 amount) public onlyTrustedContracts {
        warriors[warriorID].awardXP(amount);
    }

    function practice(uint warriorID) public onlyWarriorOwner(warriorID) onlyState(warriorID, warriorState.Idle) {
        warriors[warriorID].practice();
        emit WarriorTraining(uint64(warriorID),uint32(block.timestamp));
    }

	function stopPracticing(uint warriorID) public onlyWarriorOwner(warriorID) onlyDoneTraining(warriorID) onlyState(warriorID, warriorState.Practicing) {
        warriors[warriorID].stopPracticing();
        emit WarriorDoneTraining(uint64(warriorID),uint32(block.timestamp));
    }

    function startTeaching(uint warriorID, uint teachingFee) public onlyWarriorOwner(warriorID) onlyState(warriorID, warriorState.Idle) {
        warriors[warriorID].startTeaching(teachingFee);
        addTrainerToMarket(warriorID);
        emit NewTrainer(uint64(warriorID),teachingFee,uint32(block.timestamp));
    }

	function stopTeaching(uint warriorID) public onlyWarriorOwner(warriorID) onlyDoneTraining(warriorID) onlyState(warriorID, warriorState.Teaching) {
        warriors[warriorID].stopTeaching();
        removeTrainerFromMarket(warriorID);
        emit TrainerStopped(uint64(warriorID),uint32(block.timestamp));
    }

    function trainWith(uint warriorID, uint trainerID) public onlyWarriorOwner(warriorID) onlyState(warriorID, warriorState.Idle) onlyState(trainerID, warriorState.Teaching){
        warriors[warriorID].trainWith(warriors[trainerID]);
        trainerMapping[warriorID] = trainerID;
        emit WarriorTraining(uint64(trainerID),uint32(block.timestamp));
        emit WarriorTraining(uint64(warriorID),uint32(block.timestamp));
    }

	function stopTraining(uint warriorID) public onlyWarriorOwner(warriorID) onlyDoneTraining(warriorID) onlyState(warriorID, warriorState.Training) {
        warriors[warriorID].stopTraining(warriors[trainerMapping[warriorID]]);
        emit WarriorDoneTraining(uint64(warriorID),uint32(block.timestamp));
    }
	
    function revive(uint warriorID) public payable costsPassThrough(getReviveCost(warriorID),warriorID) onlyState(warriorID, warriorState.Incapacitated) {
        warriors[warriorID].revive();
        emit WarriorRevived(uint64(warriorID),uint32(block.timestamp));
    }

	function retire(uint warriorID) public onlyWarriorOwner(warriorID) onlyAfter(warriorID,cashoutDelay) {
        warriors[warriorID].retire();
        emit WarriorRetired(uint64(warriorID),warriors[warriorID].balance,uint32(block.timestamp));
    }

    function kill(uint warriorID) public onlyTrustedContracts {
        warriors[warriorID].kill();
    }

    function autoPotion(uint warriorID) public onlyTrustedContracts {
        warriors[warriorID].drinkPotion();
        emit WarriorDrankPotion(uint64(warriorID),uint32(block.timestamp));
    }

    function drinkPotion(uint warriorID) public onlyWarriorOwner(warriorID) onlyState(warriorID,warriorState.Idle) {
        warriors[warriorID].drinkPotion();
        emit WarriorDrankPotion(uint64(warriorID),uint32(block.timestamp));
    }

    function takeWarriorFunds(uint warriorID, uint amount) public onlyTrustedContracts {
        require(warriors[warriorID].balance >= amount);
        warriors[warriorID].balance -= amount;
    }

    function giveWarriorFunds(uint warriorID, uint amount) public onlyTrustedContracts {
        warriors[warriorID].balance += amount;
    }

    function applyDamage(uint warriorID, uint damage) public onlyTrustedContracts returns (bool) {
        return warriors[warriorID].applyDamage(damage);
    }

    function wearArmor(uint warriorID) public onlyTrustedContracts {
        warriors[warriorID].wearArmor();
    }

    function wearShield(uint warriorID) public onlyTrustedContracts {
        warriors[warriorID].wearShield();
    }

    function wearWeapon(uint warriorID) public onlyTrustedContracts {
        warriors[warriorID].wearWeapon();
    }

}
