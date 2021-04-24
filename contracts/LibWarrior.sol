// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.1;

//////////////////////////////////////////////////////////////////////////////////////////
// Data Structures
//////////////////////////////////////////////////////////////////////////////////////////

enum warriorState { 
    Idle, 
    Practicing, 
    Training, 
    Teaching, 
    BattlePending, 
    Battling, 
    Incapacitated, 
    Retired
}

enum ArmorType {
    Minimal,
    Light,
    Medium,
    Heavy
}

enum ShieldType {
    None,
    Light,
    Medium,
    Heavy
}

enum WeaponClass {
    Slashing,
    Cleaving,
    Bludgeoning,
    ExtRange
}

enum WeaponType {
    //Slashing
    Sword,              //0
    Falchion,           //1
    //Cleaving
    Broadsword,         //2
    Axe,                //3
    //Bludgeoning
    Mace,               //4
    Hammer,             //5
    Flail,              //6
    //Extended-Reach
    Trident,            //7
    Halberd,            //8
    Spear               //9
}

struct warriorStats {
    uint64 baseHP;
    uint64 dmg; 
    uint64 xp;
    uint16 str;
    uint16 dex;
    uint16 con;
    uint16 luck;
    uint64 points;
    uint16 level;
}

struct warriorEquipment {
    uint8 potions;
    uint8 intPotions;
    ArmorType armorType;
    ShieldType shieldType;
    WeaponType weaponType;
    uint8 armorStrength;
    uint8 shieldStrength;
    uint8 weaponStrength;
    uint8 armorWear;
    uint8 shieldWear;
    uint8 weaponWear;
    bool helmet;
}

struct warrior {
    //Header
    bytes32 bytesName;
    address payable owner;
    uint balance;
    uint cosmeticSeed;
    uint16 colorHue;
    warriorState state;
    uint32 creationTime;
    //Stats
    warriorStats stats;
    //Equipment
    warriorEquipment equipment;
    //Misc
    uint teachingFee;
    uint32 trainingEnds;
}

library LibWarrior {
	
    //////////////////////////////////////////////////////////////////////////////////////////
    // Config
    //////////////////////////////////////////////////////////////////////////////////////////
    
    //Warrior Attribute Factors
    uint8 constant hpConFactor = 3;
    uint8 constant hpStrFactor = 1;
    uint16 constant startingStr = 5;
    uint16 constant startingDex = 5;
    uint16 constant startingCon = 5;
    uint16 constant startingLuck = 5;
    uint16 constant startingPoints = 500;

    //Warrior Advancement
    uint8 constant levelExponent = 4;
    uint8 constant levelOffset = 4;
    uint8 constant killLevelOffset = 4;
    uint8 constant levelPointsExponent = 2;
    uint8 constant pointsLevelOffset = 6;
    uint8 constant pointsLevelMultiplier = 2;
    uint32 constant trainingTimeFactor = 1 minutes; 
    uint8 constant practiceLevelOffset = 1;
    uint16 constant intPotionFactor = 10;
    
    //Costing Config
    uint constant warriorCost = 10000000 gwei;
    uint constant warriorReviveBaseCost = warriorCost/20;
    uint constant strCostExponent = 2;
    uint constant dexCostExponent = 2;
    uint constant conCostExponent = 2;
    uint constant luckCostExponent = 3;
    uint constant potionCost = 10000000 gwei;
    uint constant intPotionCost = 50000000 gwei;
    uint constant armorCost = 1000000 gwei;
    uint constant weaponCost = 1000000 gwei;
    uint constant shieldCost = 1000000 gwei;
    uint constant armorCostExponent = 3;
    uint constant shieldCostExponent = 3;
    uint constant weaponCostExponent = 3;
    uint constant armorCostOffset = 2;
    uint constant shieldCostOffset = 2;
    uint constant weaponCostOffset = 2;

    //Value Constraints
    uint8 constant maxPotions = 5;
    uint8 constant maxIntPotions = 10;
    uint16 constant maxWeapon = 10;
    uint16 constant maxArmor = 10;
    uint16 constant maxShield = 10;

    //Misc Config
    uint32 constant cashoutDelay = 24 hours;
    uint16 constant wearPercentage = 10;
    uint16 constant potionHealAmount = 100;

    //////////////////////////////////////////////////////////////////////////////////////////
    // Modifiers
    //////////////////////////////////////////////////////////////////////////////////////////
    
    // Impossible due to Solidity Compiler Bug: https://github.com/ethereum/solidity/issues/2104

    //////////////////////////////////////////////////////////////////////////////////////////
    // Warrior Constructor
    //////////////////////////////////////////////////////////////////////////////////////////

    function newWarrior(address payable warriorOwner, uint randomSeed, uint16 colorHue, ArmorType armorType, ShieldType shieldType, WeaponType weaponType) internal view returns (warrior memory theWarrior) {
        theWarrior = warrior(
			bytes32(0),	                                        //bytesName Empty to start
			warriorOwner,			                            //owner
			0,						                            //balance
            random(randomSeed,0),                               //cosmeticSeed
            colorHue,                                           //colorHue
			warriorState.Idle,		                            //state
			uint32(block.timestamp),                            //creationTime
            warriorStats(
                uint64(calcBaseHP(0,startingCon,startingStr)),  //BaseHP
    			0,						                        //dmg
                0,						                        //xp
                startingStr,			                        //str
                startingDex,			                        //dex
                startingCon,			                        //con
                startingLuck,			                        //luck
                startingPoints,			                        //points
                0						                        //level
            ),
            warriorEquipment(
                0,						                        //potions
                0,						                        //intPotions
                armorType,                                      //armorType
                shieldType,                                     //shieldType
                weaponType,                                     //weaponType
                0,                                              //armorStrength
                0,                                              //shieldStrength
                0,                                              //weaponStrength
                0,                                              //armorWear
                0,                                              //shieldWear
                0,                                              //weaponWear
                false                                           //helmet
            ),
            0,                                                  //teachingFee
			0						                            //trainingEnds
        );
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Utilities
    //////////////////////////////////////////////////////////////////////////////////////////

    function random(uint seeda, uint seedb) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(seeda,seedb)));  
    }

	function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function bytes32ToString(bytes32 source) internal pure returns (string memory result) {
        uint8 len = 32;
        for(uint8 i;i<32;i++){
            if(source[i]==0){
                len = i;
                break;
            }
        }
        bytes memory bytesArray = new bytes(len);
        for (uint8 i=0;i<len;i++) {
            bytesArray[i] = source[i];
        }
        result = string(bytesArray);
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Derivation / Calaculation Pure Functions
    //////////////////////////////////////////////////////////////////////////////////////////

    function calcBaseHP(uint16 level, uint16 con, uint16 str) internal pure returns (uint) {
		return (con*(hpConFactor+level)) + (str*hpStrFactor);
    }

    function calcXPTargetForLevel(uint16 level) internal pure returns(uint64) {
        return (level+levelOffset) ** levelExponent;
    }

    function calcXPForPractice(uint16 level) internal pure returns (uint64) {
        return calcXPTargetForLevel(level)/(((level+practiceLevelOffset)**2)+1);
    }

    function calcDominantStatValue(uint16 con, uint16 dex, uint16 str) internal pure returns(uint16) {
        if(con>dex&&con>str) return con;
        else if(dex>con&&dex>str) return dex;
        else return str;
    }

    function calcTimeToPractice(uint16 level) internal pure returns(uint) {
		return trainingTimeFactor * ((level**levelExponent)+levelOffset);
    }

    function calcAttributeCost(uint8 amount, uint16 stat_base, uint costExponent) internal pure returns (uint cost) {
        for(uint i=0;i<amount;i++){
            cost += (stat_base + i) ** costExponent;
        }
    }
    
    function calcItemCost(uint8 amount, uint8 currentVal, uint baseCost, uint offset, uint exponent) internal pure returns (uint cost) {
        for(uint i=0;i<amount;i++){
            cost += ((i + 1 + currentVal + offset) ** exponent) * baseCost;
        }
    }

    function calcReviveCost(uint16 level) internal pure returns(uint) {
        return ((level ** 2) +1) * warriorReviveBaseCost;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Derived/Calculated Getters
    //////////////////////////////////////////////////////////////////////////////////////////

    function getName(warrior storage w) public view returns(string memory name) {
        name = bytes32ToString(w.bytesName);
    }

    function getHP(warrior storage w) public view returns (int) {
        return int(int64(w.stats.baseHP) - int64(w.stats.dmg));
    }

    function getWeaponClass(warrior storage w) public view returns (WeaponClass) {
        if((w.equipment.weaponType==WeaponType.Broadsword || w.equipment.weaponType==WeaponType.Axe)) return WeaponClass.Cleaving;
        if((w.equipment.weaponType==WeaponType.Mace || w.equipment.weaponType==WeaponType.Hammer || w.equipment.weaponType==WeaponType.Flail)) return WeaponClass.Bludgeoning;
        if((w.equipment.weaponType==WeaponType.Trident || w.equipment.weaponType==WeaponType.Halberd || w.equipment.weaponType==WeaponType.Spear)) return WeaponClass.ExtRange;        
        //Default, (w.weaponType==WeaponType.Sword || w.weaponType==WeaponType.Falchion):
        return WeaponClass.Slashing;
    }
   
    function canLevelUp(warrior storage w) public view returns(bool) {
        return (w.stats.xp >= calcXPTargetForLevel(w.stats.level));
    }

    function canRevive(warrior storage w) public view returns(bool) {
		return w.state == warriorState.Incapacitated;
    }

    function getCosmeticProperty(warrior storage w, uint propertyIndex) public view returns (uint) {
        return random(w.cosmeticSeed,propertyIndex);
    }

    function getEquipLevel(warrior storage w) public view returns (uint) {
        if(w.equipment.weaponStrength>w.equipment.armorStrength && w.equipment.weaponStrength>w.equipment.shieldStrength){
            return w.equipment.weaponStrength;
        }else{
            if(w.equipment.armorStrength>w.equipment.shieldStrength){
                return w.equipment.armorStrength;
            }else{
                return w.equipment.shieldStrength;
            }
        }
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Costing Getters
    //////////////////////////////////////////////////////////////////////////////////////////

    function getStatsCost(warrior storage w, uint8 strAmount, uint8 dexAmount, uint8 conAmount, uint8 luckAmount) public view returns (uint) {
        return (
            calcAttributeCost(strAmount,w.stats.str,strCostExponent)+
            calcAttributeCost(dexAmount,w.stats.dex,dexCostExponent)+
            calcAttributeCost(conAmount,w.stats.con,conCostExponent)+
            calcAttributeCost(luckAmount,w.stats.luck,luckCostExponent)
        );
    }
    
    function getEquipCost(warrior storage w, uint8 armorAmount, uint8 shieldAmount, uint8 weaponAmount, uint8 potionAmount, uint8 intPotionAmount) public view returns(uint) {
        return (
            calcItemCost(armorAmount,w.equipment.armorStrength,armorCost,armorCostOffset,armorCostExponent)+
            calcItemCost(shieldAmount,w.equipment.shieldStrength,shieldCost,shieldCostOffset,shieldCostExponent)+
            calcItemCost(weaponAmount,w.equipment.weaponStrength,weaponCost,weaponCostOffset,weaponCostExponent)+
            (potionCost*potionAmount)+
            (intPotionCost+intPotionAmount)
        );
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Setters
    //////////////////////////////////////////////////////////////////////////////////////////

    function setName(warrior storage w, string memory name) public {
        require(w.bytesName==bytes32(0));
        w.bytesName = stringToBytes32(name);
    }

    function setOwner(warrior storage w, address payable newOwner) public {
        w.owner = newOwner;
    }

	function setState(warrior storage w, warriorState _state) public {
		w.state = _state;
	}

    //////////////////////////////////////////////////////////////////////////////////////////
    // Buying Things
    //////////////////////////////////////////////////////////////////////////////////////////

    function buyStats(warrior storage w, uint8 strAmount, uint8 dexAmount, uint8 conAmount, uint8 luckAmount) public {
        require(strAmount>0 || dexAmount>0 || conAmount>0 || luckAmount>0); //Require buying at least something, otherwise you are wasting gas!
        w.stats.str += strAmount;
        w.stats.dex += dexAmount;
        w.stats.con += conAmount;
        w.stats.luck += luckAmount;
        w.stats.baseHP = uint64(calcBaseHP(w.stats.level,w.stats.con,w.stats.str));
    }

    function buyEquipment(warrior storage w, uint8 armorAmount, uint8 shieldAmount, uint8 weaponAmount, uint8 potionAmount, uint8 intPotionAmount) public {
        require(armorAmount>0 || shieldAmount>0 || weaponAmount>0 || potionAmount>0 || intPotionAmount>0); //Require buying at least something, otherwise you are wasting gas!
        require((w.equipment.potions+potionAmount) <= maxPotions);
        require((w.equipment.intPotions+intPotionAmount) <= maxIntPotions);
        w.equipment.armorStrength += armorAmount;
        w.equipment.shieldStrength += shieldAmount;
        w.equipment.weaponStrength += weaponAmount;
        w.equipment.potions += potionAmount;
        w.equipment.intPotions += intPotionAmount;
    }    

    //////////////////////////////////////////////////////////////////////////////////////////
    // Transaction/Payment Handling
    //////////////////////////////////////////////////////////////////////////////////////////

	function receiveFunds(warrior storage w,uint amount,bool tax) public {
		if(tax) {
			//TODO: Founders Guild?
			uint ownerValue = amount / 100;
			uint warriorValue = amount - ownerValue;
			w.balance += warriorValue;
			w.owner.transfer(ownerValue);
		} else {
			w.balance += amount;
		}
	}

    //////////////////////////////////////////////////////////////////////////////////////////
    // Actions/Activities/Effects
    //////////////////////////////////////////////////////////////////////////////////////////

    function levelUp(warrior storage w) public {
        require(w.stats.xp >= calcXPTargetForLevel(w.stats.level));
        w.stats.level++;
        w.stats.str++;
        w.stats.dex++;
        w.stats.con++;
        w.stats.points += ((w.stats.level+pointsLevelOffset) * pointsLevelMultiplier) ** levelPointsExponent;
        w.stats.baseHP = uint64(calcBaseHP(w.stats.level,w.stats.con,w.stats.str));
    }

	function awardXP(warrior storage w, uint64 amount) public {
		w.stats.xp += amount;
        if(canLevelUp(w)) levelUp(w);
    }

    function practice(warrior storage w) public {
		w.state = warriorState.Practicing;
        if(w.equipment.intPotions>0){
            w.equipment.intPotions--;
            w.trainingEnds = uint32(block.timestamp + (calcTimeToPractice(w.stats.level)/intPotionFactor));
        }else{
            w.trainingEnds = uint32(block.timestamp + calcTimeToPractice(w.stats.level)); 
        }
    }

	function stopPracticing(warrior storage w) public {
        awardXP(w,calcXPForPractice(w.stats.level));
        w.state = warriorState.Idle;
    }

    function startTeaching(warrior storage w, uint teachingFee) public {
        w.teachingFee = teachingFee;
        w.state = warriorState.Teaching;
    }

	function stopTeaching(warrior storage w) public {
        w.state = warriorState.Idle;
    }

    function canTrainWith(warrior storage w, warrior storage t) public view returns(bool) {
        return (
            w.balance >= t.teachingFee &&
            t.stats.level > w.stats.level &&
            calcDominantStatValue(t.stats.con,t.stats.dex,t.stats.str)>calcDominantStatValue(w.stats.con,w.stats.dex,w.stats.str) && 
            block.timestamp >= t.trainingEnds
        );
    }

    function trainWith(warrior storage w, warrior storage t) public {
        require(canTrainWith(w,t));
        w.balance -= t.teachingFee;
        receiveFunds(t,t.teachingFee,true);
        w.state = warriorState.Training;
        if(w.equipment.intPotions>0){
            w.equipment.intPotions--;
            w.trainingEnds = uint32(block.timestamp + (calcTimeToPractice(w.stats.level)/intPotionFactor));
            t.trainingEnds = w.trainingEnds;
        }else{
            w.trainingEnds = uint32(block.timestamp + calcTimeToPractice(w.stats.level));
            t.trainingEnds = w.trainingEnds;
        }
    }

	function stopTraining(warrior storage w, warrior storage t) public {
        uint16 trainerDominantStatVal = calcDominantStatValue(t.stats.con,t.stats.dex,t.stats.str);
        if(trainerDominantStatVal==t.stats.str) w.stats.str++;
        else if(trainerDominantStatVal==t.stats.dex) w.stats.dex++;
        else w.stats.con++;
        w.stats.baseHP = uint64(calcBaseHP(w.stats.level,w.stats.con,w.stats.str));
        w.state = warriorState.Idle;
    }

    function revive(warrior storage w) public {
        require(canRevive(w));
		w.state = warriorState.Idle;
        w.stats.dmg = 0;
    }

	function retire(warrior storage w) public {
		require(w.state != warriorState.BattlePending && w.state != warriorState.Battling && w.state != warriorState.Retired);
		w.state = warriorState.Retired;
        w.owner.transfer(w.balance);
    }

    function kill(warrior storage w) public {
		w.state = warriorState.Incapacitated;
    }

    function drinkPotion(warrior storage w) public {
		require(w.equipment.potions>0);
        require(w.stats.dmg>0);
        w.equipment.potions--;
        if(w.stats.dmg>potionHealAmount){
            w.stats.dmg -= potionHealAmount;
        }else{
            w.stats.dmg = 0;
        }
    }

    function applyDamage(warrior storage w, uint damage) public returns (bool resultsInDeath) {
		w.stats.dmg += uint64(damage);
        if(w.stats.dmg >= w.stats.baseHP) w.stats.dmg = w.stats.baseHP;
        resultsInDeath = (getHP(w) <= 0);
    }

    function wearWeapon(warrior storage w) public {
        if(w.equipment.weaponStrength>0){
            w.equipment.weaponWear++;
            if(w.equipment.weaponWear>((maxWeapon+1)-w.equipment.weaponStrength)){ //Wear increases as you approach max level
                w.equipment.weaponStrength--;
                w.equipment.weaponWear=0;
            }
        }
    }

    function wearArmor(warrior storage w) public {
        if(w.equipment.armorStrength>0){
            w.equipment.armorWear++;
            if(w.equipment.armorWear>((maxArmor+1)-w.equipment.armorStrength)){ //Wear increases as you approach max level
                w.equipment.armorStrength--;
                w.equipment.armorWear=0;
            }
        }
    }

    function wearShield(warrior storage w) public {
        if(w.equipment.shieldStrength>0){
            w.equipment.shieldWear++;
            if(w.equipment.shieldWear>((maxShield+1)-w.equipment.shieldStrength)){ //Wear increases as you approach max level
                w.equipment.shieldStrength--;
                w.equipment.shieldWear=0;
            }
        }
    }
}