// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.1;

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

    struct warrior {
		bytes32 bytesName;
		//Storage Cell 1 End
		address payable owner;
		//Storage Cell 2 End
		uint balance;
		//Storage Cell 3 End
		uint teachingFee;
		//Storage Cell 4 End
		uint salePrice;
		//Storage Cell 5 End
		uint cosmeticSeed;
		//Storage Cell 6 End
		uint64 xp;
		uint64 dmg; 
		uint32 creationTime;
		uint32 trainingEnds;
		uint16 str;
		uint16 dex;
		uint16 con;
		uint16 luck;
		//Storage Cell 7 End
		uint64 points;
        uint16 colorHue;
		uint16 level;
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
		warriorState state;
		//Storage Cell 8 End
	}

    //////////////////////////////////////////////////////////////////////////////////////////
    // Modifiers
    //////////////////////////////////////////////////////////////////////////////////////////
    
    // Impossible due to Solidity Compiler Bug: https://github.com/ethereum/solidity/issues/2104

    //////////////////////////////////////////////////////////////////////////////////////////
    // Warrior Constructor
    //////////////////////////////////////////////////////////////////////////////////////////

    function newWarrior(address payable warriorOwner, uint randomSeed, uint16 colorHue, ArmorType armorType, ShieldType shieldType, WeaponType weaponType) internal view returns (warrior memory theWarrior) {
        theWarrior = warrior(
			bytes32(0),	            //bytesName Empty to start
			warriorOwner,			//owner
			0,						//balance
            0,                      //teachingFee
            0,                      //salePrice
            random(randomSeed,0),   //cosmeticSeed
			0,						//xp
			0,						//dmg
			uint32(block.timestamp),			//creationTime
			0,						//trainingEnds
			startingStr,			//str
			startingDex,			//dex
			startingCon,			//con
			startingLuck,			//luck
			startingPoints,			//points
            colorHue,               //colorHue
			0,						//level
			0,						//potions
			0,						//intPotions
            armorType,              //armorType
            shieldType,             //shieldType
            weaponType,             //weaponType
            0,                      //armorStrength
            0,                      //shieldStrength
            0,                      //weaponStrength
            0,                      //armorWear
            0,                      //shieldWear
            0,                      //weaponWear
            false,                  //helmet
			warriorState.Idle		//state
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
    // Derived/Calculated Getters
    //////////////////////////////////////////////////////////////////////////////////////////

    function getName(warrior storage w) internal view returns(string memory name) {
        name = bytes32ToString(w.bytesName);
    }

    function getBaseHP(warrior storage w) internal view returns (uint) {
		return (w.con*(hpConFactor+w.level)) + (w.str*hpStrFactor);
    }

    function getHP(warrior storage w) internal view returns (int) {
        return int(getBaseHP(w) - w.dmg);
    }

    function getWeaponClass(warrior storage w) internal view returns (WeaponClass) {
        if((w.weaponType==WeaponType.Broadsword || w.weaponType==WeaponType.Axe)) return WeaponClass.Cleaving;
        if((w.weaponType==WeaponType.Mace || w.weaponType==WeaponType.Hammer || w.weaponType==WeaponType.Flail)) return WeaponClass.Bludgeoning;
        if((w.weaponType==WeaponType.Trident || w.weaponType==WeaponType.Halberd || w.weaponType==WeaponType.Spear)) return WeaponClass.ExtRange;        
        //if((w.weaponType==WeaponType.Sword || w.weaponType==WeaponType.Falchion)) return WeaponClass.Slashing;
        //Default:
        return WeaponClass.Slashing;
    }
   
    function getArmorMod(warrior storage w) internal view returns(int con, int str, int dex) {
        if(w.armorType==ArmorType.Minimal) {
            con=-1;
            dex=1;
            str=0;
        }
        else if(w.armorType==ArmorType.Light) {
            con=0;
            dex=0;
            str=0;
        }
        else if(w.armorType==ArmorType.Medium) {
            con=1;
            dex=-1;
            str=0;
        }
        else if(w.armorType==ArmorType.Heavy) {
            con=2;
            dex=-2;
            str=0;
        }
        con *= int8(w.armorStrength);
        dex *= int8(w.armorStrength);
        str *= int8(w.armorStrength);
    }

    function getShieldMod(warrior storage w) internal view returns(int con, int str, int dex) {
        if(w.shieldType==ShieldType.None) {
            con=0;
            dex=0;
            str=0;
        }
        else if(w.shieldType==ShieldType.Light) {
            con=1;
            dex=-1;
            str=-1;
        }
        else if(w.shieldType==ShieldType.Medium) {
            con=2;
            dex=-2;
            str=-1;
        }
        else if(w.shieldType==ShieldType.Heavy) {
            con=3;
            dex=-3;
            str=-2;
        }
        con *= int8(w.shieldStrength);
        dex *= int8(w.shieldStrength);
        str *= int8(w.shieldStrength);
    }

    function getWeaponMod(warrior storage w) internal view returns(int con, int str, int dex) {
        WeaponClass wc = getWeaponClass(w);
        if(wc==WeaponClass.Slashing) {
            con=0;
            dex=1;
            str=0;
        } 
        if(wc==WeaponClass.Cleaving) {
            con=0;
            dex=-1;
            str=1;
        } 
        if(wc==WeaponClass.Bludgeoning) {
            con=0;
            dex=-2;
            str=1;
        } 
        if(wc==WeaponClass.ExtRange) {
            con=0;
            dex=1;
            str=-2;
        } 
        con *= int8(w.weaponStrength);
        dex *= int8(w.weaponStrength);
        str *= int8(w.weaponStrength);
    }

    function getHelmetMod(warrior storage w) internal view returns(int con, int str, int dex) {
        if(w.helmet) {
            con = 1;
            dex = -1;
            str = 0;
        }else{
            con = 0;
            dex = 0;
            str = 0;
        }
    }

    function getEquipmentMods(warrior storage w) internal view returns(int con, int str, int dex) {
        int tcon;
        int tstr;
        int tdex;
        (tcon, tstr, tdex) = getArmorMod(w);
        con += tcon;
        str += tstr;
        dex += tdex;
        (tcon, tstr, tdex) = getShieldMod(w);
        con += tcon;
        str += tstr;
        dex += tdex;
        (tcon, tstr, tdex) = getWeaponMod(w);
        con += tcon;
        str += tstr;
        dex += tdex;
        (tcon, tstr, tdex) = getHelmetMod(w);
        con += tcon;
        str += tstr;
        dex += tdex;
    }

    function getCombatCon(warrior storage w) internal view returns(uint16) {
        int conmod;
        int strmod;
        int dexmod;
        int val;
        (conmod,strmod,dexmod) = getEquipmentMods(w);
        val = int16(w.con) + conmod;
        if(val<=0) val=1;
        if(val>=0xFFFF) val=0xFFFF;
        return uint16(int16(val));
    }

    function getCombatStr(warrior storage w) internal view returns(uint16) {
        int conmod;
        int strmod;
        int dexmod;
        int val;
        (conmod,strmod,dexmod) = getEquipmentMods(w);
        val = int16(w.str) + strmod;
        if(val<=0) val=1;
        if(val>=0xFFFF) val=0xFFFF;
        return uint16(int16(val));
    }

    function getCombatDex(warrior storage w) internal view returns(uint16) {
        int conmod;
        int strmod;
        int dexmod;
        int val;
        (conmod,strmod,dexmod) = getEquipmentMods(w);
        val = int16(w.dex) + dexmod;
        if(val<=0) val=1;
        if(val>=0xFFFF) val=0xFFFF;
        return uint16(int16(val));
    }

    function getXPTargetForLevel(uint16 level) internal pure returns(uint64) {
        return (level+levelOffset) ** levelExponent;
    }

    function canLevelUp(warrior storage w) internal view returns(bool) {
        return (w.xp >= getXPTargetForLevel(w.level));
    }

    function getXPForKill(warrior storage w, uint16 killLevel) internal view returns (uint64) {
        if(killLevel-w.level+killLevelOffset > 1) 
            return ((killLevel+killLevelOffset)-w.level) ** levelExponent;
        else
            return 1;
    }

    function getXPForPractice(warrior storage w) internal view returns (uint64) {
        return getXPTargetForLevel(w.level)/(((w.level+practiceLevelOffset)**2)+1);
    }

    function getDominantStatValue(warrior storage w) internal view returns(uint16) {
        if(w.con>w.dex&&w.con>w.str) return w.con;
        else if(w.dex>w.con&&w.dex>w.str) return w.dex;
        else return w.str;
    }

    function getTimeToPractice(warrior storage w) internal view returns(uint) {
		return trainingTimeFactor * ((w.level**levelExponent)+levelOffset);
    }

    function canRevive(warrior storage w) internal view returns(bool) {
		return w.state == warriorState.Incapacitated;
    }

    function getDamageReduction(warrior storage w) internal view returns (uint64) {
        return getCombatCon(w);
    }

    function getCosmeticProperty(warrior storage w, uint propertyIndex) internal view returns (uint) {
        return random(w.cosmeticSeed,propertyIndex);
    }

    function getEquipLevel(warrior storage w) internal view returns (uint) {
        if(w.weaponStrength>w.armorStrength && w.weaponStrength>w.shieldStrength){
            return w.weaponStrength;
        }else{
            if(w.armorStrength>w.shieldStrength){
                return w.armorStrength;
            }else{
                return w.shieldStrength;
            }
        }
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Costing Getters
    //////////////////////////////////////////////////////////////////////////////////////////

    function getAttributeCost(uint8 amount, uint16 stat_base, uint costExponent) internal pure returns (uint cost) {
        for(uint i=0;i<amount;i++){
            cost += (stat_base + i) ** costExponent;
        }
    }

    function getStrCost(warrior storage w, uint8 amount) internal view returns (uint) {
        return getAttributeCost(amount,w.str,strCostExponent);
    }

    function getDexCost(warrior storage w, uint8 amount) internal view returns (uint) {
        return getAttributeCost(amount,w.dex,dexCostExponent);
    }

    function getConCost(warrior storage w, uint8 amount) internal view returns (uint) {
        return getAttributeCost(amount,w.con,conCostExponent);
    }

    function getLuckCost(warrior storage w, uint8 amount) internal view returns (uint) {
        return getAttributeCost(amount,w.luck,luckCostExponent);
    }

    function getStatsCost(warrior storage w, uint8 strAmount, uint8 dexAmount, uint8 conAmount, uint8 luckAmount) internal view returns (uint) {
        return getStrCost(w,strAmount) + getDexCost(w,dexAmount) + getConCost(w,conAmount) + getLuckCost(w,luckAmount);
    }

    function getItemCost(uint8 amount, uint8 currentVal, uint baseCost, uint offset, uint exponent) internal pure returns (uint cost) {
        for(uint i=0;i<amount;i++){
            cost += ((i + 1 + currentVal + offset) ** exponent) * baseCost;
        }
    }

    function getArmorCost(warrior storage w, uint8 amount) internal view returns(uint) {
        return getItemCost(amount,w.armorStrength,armorCost,armorCostOffset,armorCostExponent);
    }

    function getShieldCost(warrior storage w, uint8 amount) internal view returns(uint) {
        return getItemCost(amount,w.shieldStrength,shieldCost,shieldCostOffset,shieldCostExponent);
    }

    function getWeaponCost(warrior storage w, uint8 amount) internal view returns(uint) {
        return getItemCost(amount,w.weaponStrength,weaponCost,weaponCostOffset,weaponCostExponent);
    }

    function getPotionCost(uint8 amount) internal pure returns(uint) {
        return potionCost * amount;        
    }

    function getIntPotionCost(uint8 amount) internal pure returns(uint) {
        return intPotionCost * amount;        
    }

    function getEquipCost(warrior storage w, uint8 armorAmount, uint8 shieldAmount, uint8 weaponAmount, uint8 potionAmount, uint8 intPotionAmount) internal view returns(uint) {
        return getArmorCost(w, armorAmount) + getShieldCost(w, shieldAmount) + getWeaponCost(w, weaponAmount) + getPotionCost(potionAmount) + getIntPotionCost(intPotionAmount);
    }

    function getReviveCost(warrior storage w) internal view returns(uint) {
        return ((w.level ** 2) +1) * warriorReviveBaseCost;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Setters
    //////////////////////////////////////////////////////////////////////////////////////////

    function setName(warrior storage w, string memory name) internal {
        require(w.bytesName==bytes32(0));
        w.bytesName = stringToBytes32(name);
    }

    function setOwner(warrior storage w, address payable newOwner) internal {
        w.owner = newOwner;
    }

	function setState(warrior storage w, warriorState _state) internal {
		w.state = _state;
	}

    //////////////////////////////////////////////////////////////////////////////////////////
    // Buying Things
    //////////////////////////////////////////////////////////////////////////////////////////

    function buyStrInternal(warrior storage w, uint8 amount) internal {
		w.str += amount;
    }

    function buyDexInternal(warrior storage w, uint8 amount) internal {
		w.dex += amount;
    }

    function buyConInternal(warrior storage w, uint8 amount) internal {
		w.con += amount;
    }

    function buyLuckInternal(warrior storage w, uint8 amount) internal {
		w.luck += amount;
    }

    function buyStats(warrior storage w, uint8 strAmount, uint8 dexAmount, uint8 conAmount, uint8 luckAmount) internal {
        require(strAmount>0 || dexAmount>0 || conAmount>0 || luckAmount>0); //Require buying at least something, otherwise you are wasting gas!
        buyStrInternal(w,strAmount);
        buyDexInternal(w,dexAmount);
        buyConInternal(w,conAmount);
        buyLuckInternal(w,luckAmount);        
    }

    function buyPotionsInternal(warrior storage w, uint8 amount) internal {
		require((w.potions+amount) < maxPotions);
		w.potions = w.potions + amount;
    }

    function buyIntPotionsInternal(warrior storage w, uint8 amount) internal {
        require((w.intPotions+amount) < maxIntPotions);
		w.intPotions = w.intPotions + amount;
    }

    function buyArmorInternal(warrior storage w, uint8 amount) internal {
        require((w.armorStrength+amount) < maxArmor);        
		w.armorStrength += amount;
    }
    
    function buyShieldInternal(warrior storage w, uint8 amount) internal {
        require((w.shieldStrength+amount) < maxArmor);        
		w.shieldStrength += amount;
    }

    function buyWeaponInternal(warrior storage w, uint8 amount) internal {
        require((w.weaponStrength+amount) < maxWeapon);
		w.weaponStrength += amount;
    }

    function buyEquipment(warrior storage w, uint8 armorAmount, uint8 shieldAmount, uint8 weaponAmount, uint8 potionAmount, uint8 intPotionAmount) internal {
        buyArmorInternal(w,armorAmount);
        buyShieldInternal(w,shieldAmount);
        buyWeaponInternal(w,weaponAmount);
        buyPotionsInternal(w,potionAmount);
        buyIntPotionsInternal(w,intPotionAmount);
    }    

    //////////////////////////////////////////////////////////////////////////////////////////
    // Transaction/Payment Handling
    //////////////////////////////////////////////////////////////////////////////////////////

	function payWarriorInternal(warrior storage w,uint amount,bool tax) internal {
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

    function levelUp(warrior storage w) internal {
        require(w.xp >= getXPTargetForLevel(w.level));
        w.level++;
        w.str++;
        w.dex++;
        w.con++;
        w.points += ((w.level+pointsLevelOffset) * pointsLevelMultiplier) ** levelPointsExponent;
    }

	function awardXP(warrior storage w, uint64 _xp) internal {
		w.xp += _xp;
        if(canLevelUp(w)) levelUp(w);
    }

    function earnXPForKill(warrior storage w, uint killLevel) internal {
        awardXP(w,getXPForKill(w,uint16(killLevel)));
    }

    function practice(warrior storage w) internal {
		w.state = warriorState.Practicing;
        if(w.intPotions>0){
            w.intPotions--;
            w.trainingEnds = uint32(block.timestamp + (getTimeToPractice(w)/intPotionFactor));
        }else{
            w.trainingEnds = uint32(block.timestamp + getTimeToPractice(w));
        }
    }

	function stopPracticing(warrior storage w) internal {
        awardXP(w,getXPForPractice(w));
        w.state = warriorState.Idle;
    }

    function startTeaching(warrior storage w, uint teachingFee) internal {
        w.teachingFee = teachingFee;
        w.state = warriorState.Teaching;
    }

	function stopTeaching(warrior storage w) internal {
        w.state = warriorState.Idle;
    }

    function canTrainWith(warrior storage w, warrior storage t) internal view returns(bool) {
        return (
            w.balance >= t.teachingFee &&
            t.level > w.level &&
            getDominantStatValue(t)>getDominantStatValue(w) &&
            block.timestamp >= t.trainingEnds
        );
    }

    function trainWith(warrior storage w, warrior storage t) internal {
        require(canTrainWith(w,t));
        w.balance -= t.teachingFee;
        payWarriorInternal(t,t.teachingFee,true);
        w.state = warriorState.Training;
        if(w.intPotions>0){
            w.intPotions--;
            w.trainingEnds = uint32(block.timestamp + (getTimeToPractice(w)/intPotionFactor));
            t.trainingEnds = w.trainingEnds;
        }else{
            w.trainingEnds = uint32(block.timestamp + getTimeToPractice(w));
            t.trainingEnds = w.trainingEnds;
        }
    }

	function stopTraining(warrior storage w, warrior storage t) internal {
        if(getDominantStatValue(t)==t.str) w.str++;
        else if(getDominantStatValue(t)==t.dex) w.dex++;
        else w.con++;
        w.state = warriorState.Idle;
    }

    function revive(warrior storage w) internal {
        require(canRevive(w));
		w.state = warriorState.Idle;
        w.dmg = 0;
    }

	function retire(warrior storage w) internal {
		require(w.state != warriorState.BattlePending && w.state != warriorState.Battling);
		w.state = warriorState.Retired;
        w.owner.transfer(w.balance);
    }

    function kill(warrior storage w) internal {
		w.state = warriorState.Incapacitated;
    }

    function drinkPotion(warrior storage w) internal {
		require(w.potions>0);
        require(w.dmg>0);
        w.potions--;
        if(w.dmg>potionHealAmount){
            w.dmg -= potionHealAmount;
        }else{
            w.dmg = 0;
        }
    }

    function applyDamage(warrior storage w, uint damage) internal returns (bool resultsInDeath) {
		w.dmg += uint64(damage);
        if(w.dmg >= getBaseHP(w)) w.dmg = uint64(getBaseHP(w));
        resultsInDeath = (getHP(w) <= 0);
    }

    function wearWeapon(warrior storage w) internal {
        if(w.weaponStrength>0){
            w.weaponWear++;
            if(w.weaponWear>((maxWeapon+1)-w.weaponStrength)){ //Wear increases as you approach max level
                w.weaponStrength--;
                w.weaponWear=0;
            }
        }
    }

    function wearArmor(warrior storage w) internal {
        if(w.armorStrength>0){
            w.armorWear++;
            if(w.armorWear>((maxArmor+1)-w.armorStrength)){ //Wear increases as you approach max level
                w.armorStrength--;
                w.armorWear=0;
            }
        }
    }

    function wearShield(warrior storage w) internal {
        if(w.shieldStrength>0){
            w.shieldWear++;
            if(w.shieldWear>((maxShield+1)-w.shieldStrength)){ //Wear increases as you approach max level
                w.shieldStrength--;
                w.shieldWear=0;
            }
        }
    }
}