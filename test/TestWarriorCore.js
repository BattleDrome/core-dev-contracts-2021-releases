var WarriorCore = artifacts.require("WarriorCore.sol");

contract('WarriorCore', function(accounts) {
    var BDTestLib = require('./BDTestLib.js')

    before(async () => {
        console.log("   Pre-Test Initialization:")
        //Check deployed instances
        console.log("       Initializing Deployed Instances...")
        warriorInstance = await WarriorCore.deployed();

        //Setup test library
        console.log("       Initializing BDTestLib Testing Harness...")
        BDTestLib.init(accounts,null,warriorInstance,null,null)

        //Check Library Setup
        console.log("       Verifying BDTestLib Testing Harness Initialization...")
        assert.isNotNull(BDTestLib.warriorCoreInstance,"Warrior Core Instance was Null!");

        console.log("   Pre-Test Initialization Complete!")
    });

    it("Should start with zero warriors", async () => {
        var warriorCount = await BDTestLib.warriorCoreInstance.getGlobalWarriorCount.call();
        assert.equal(warriorCount,0,"WarriorCore started with non-zero warrior count!");
    });

    it("WarriorCount of Main Account should start as zero", async () => {
        var warriorCount = await BDTestLib.warriorCoreInstance.getWarriorCount.call(accounts[0]);
        assert.equal(warriorCount,0,"Main Account started with non-zero warrior count!");
    });

    it("Should allow Creation of a new Warrior (with reasonable gas cost)", async () => {
        var warriorFee = await BDTestLib.warriorCoreInstance.getWarriorCost.call();
        var txResult = await BDTestLib.warriorCoreInstance.newWarrior(accounts[0],0,0,0,0,{value:warriorFee});
        var eventFound = false;
        var warriorID = 0;
        var warriorCount = 0;
        var gasUsed = txResult.receipt.cumulativeGasUsed;
        for(var i=0; i<txResult.logs.length; i++) {
            var log = txResult.logs[i];
            if(log.event=="WarriorCreated"){
                eventFound = true;
                warriorID = log.args.warrior;
                warriorCount = await BDTestLib.warriorCoreInstance.getGlobalWarriorCount.call();
                ownerWarriorCount = await BDTestLib.warriorCoreInstance.getWarriorCount.call(accounts[0]);
            }
        }
        assert.isTrue(eventFound, "The WarriorCreated Event was not detected!");
        assert.isAbove(+warriorCount, 0, "The WarriorCount does not reflect the new warrior!");
        assert.isAbove(+ownerWarriorCount, 0, "The WarriorCount for the Main Account does not reflect the new warrior!");
        assert.isBelow(+gasUsed,500000,"The newWarrior method call consumed more than 500,000 units of gas! Unacceptable!");
    });

    it("Should allow Creation of Multiple Warriors", async () => {
        var warriorFee = await BDTestLib.warriorCoreInstance.getWarriorCost.call();
        var txResultA = await BDTestLib.warriorCoreInstance.newWarrior(accounts[0],0,0,0,0,{value:warriorFee});
        var txResultB = await BDTestLib.warriorCoreInstance.newWarrior(accounts[0],0,0,0,0,{value:warriorFee});
        var eventFoundA = false;
        var eventFoundB = false;
        var warriorCount = 0;
        for(var i=0; i<txResultA.logs.length; i++) {
            var log = txResultA.logs[i];
            if(log.event=="WarriorCreated"){
                eventFoundA = true;
            }
        }
        for(var i=0; i<txResultB.logs.length; i++) {
            var log = txResultB.logs[i];
            if(log.event=="WarriorCreated"){
                eventFoundB = true;
            }
        }
        warriorCount = await BDTestLib.warriorCoreInstance.getGlobalWarriorCount.call();
        assert.isTrue(eventFoundA, "The WarriorCreated Event was not detected for the second warrior!");
        assert.isTrue(eventFoundA, "The WarriorCreated Event was not detected for the third warrior!");
        assert.isAbove(+warriorCount, 2, "The WarriorCount does not reflect the new warriors!");
    });

    it("Should start with no name", async () => {
        var name = await BDTestLib.warriorCoreInstance.getName.call(0);
        assert.equal(name,"","Warrior didn't have a blank name!");
        var name = await BDTestLib.warriorCoreInstance.getName.call(1);
        assert.equal(name,"","Warrior didn't have a blank name!");
        var name = await BDTestLib.warriorCoreInstance.getName.call(2);
        assert.equal(name,"","Warrior didn't have a blank name!");
    });

    it("Should allow naming new warriors", async () => {
        await BDTestLib.warriorCoreInstance.setName(0,"Bob");
        await BDTestLib.warriorCoreInstance.setName(1,"Joe");
        await BDTestLib.warriorCoreInstance.setName(2,"Dave");
        var bobName = await BDTestLib.warriorCoreInstance.getName.call(0);
        var joeName = await BDTestLib.warriorCoreInstance.getName.call(1);
        var daveName = await BDTestLib.warriorCoreInstance.getName.call(2);
        assert.equal(bobName,"Bob","Warrior didn't have the correct name!");
        assert.equal(joeName,"Joe","Warrior didn't have the correct name!");
        assert.equal(daveName,"Dave","Warrior didn't have the correct name!");
    });

    it("Should start at level zero", async () => {
        var level = await BDTestLib.warriorCoreInstance.getLevel.call(0);
        assert.equal(level.toNumber(),0,"Warrior had non-zero level to start!");
    });

    it("Should start in state Idle", async () => {
        var state = await BDTestLib.warriorCoreInstance.getState.call(0);
        assert.equal(state.toNumber(),0,"Warrior is not starting in Idle State!");
    });

    it("Should start with appropriate starting stats", async () => {
        var str = await BDTestLib.warriorCoreInstance.getStr.call(0);
        var dex = await BDTestLib.warriorCoreInstance.getDex.call(0);
        var con = await BDTestLib.warriorCoreInstance.getCon.call(0);
        var luck = await BDTestLib.warriorCoreInstance.getLuck.call(0);
        assert.equal(str.toNumber(),5,"Warrior had wrong starting STR value");
        assert.equal(dex.toNumber(),5,"Warrior had wrong starting DEX value");
        assert.equal(con.toNumber(),5,"Warrior had wrong starting CON value");
        assert.equal(luck.toNumber(),5,"Warrior had wrong starting LUCK value");
    })

    it("Should start with no damage", async () => {
        var damage = await BDTestLib.warriorCoreInstance.getDmg.call(0);
        assert.equal(damage.toNumber(),0,"Warrior started with damage!");
    });
    
    it("Should start with appropriate hitpoints", async () => {
        var str = await BDTestLib.warriorCoreInstance.getStr.call(0);
        var con = await BDTestLib.warriorCoreInstance.getCon.call(0);
        var level = await BDTestLib.warriorCoreInstance.getLevel.call(0);
        var hpConFactor = 3;
        var hpStrFactor = 1;
        //OMG Javascript crash and die a horrible burning death!!!!
        //TODO: Fix this from concatenating to string, to do real math... 
        //Javascript... WTF?!?!?!?!
        //var desiredHP = (parseInt(con)*parseInt(hpConFactor)*parseInt(level))+(parseInt(str)*parseInt(hpStrFactor));
        var desiredHP = 20;
        var hp = await BDTestLib.warriorCoreInstance.getHP.call(0);
        assert.equal(hp.toNumber(),desiredHP,"Warrior had incorrect starting HP!");
    });

    it("Should start with appropriate starting points", async () => {
        var points = await BDTestLib.warriorCoreInstance.getPoints.call(0);
        assert.equal(points.toNumber(),500,"Warrior did not start with correct amount of points!");
    });

    it("Should not start with any equipment", async () => {
        var armor = await BDTestLib.warriorCoreInstance.getArmor.call(0);
        var shield = await BDTestLib.warriorCoreInstance.getShield.call(0);
        var weapon = await BDTestLib.warriorCoreInstance.getWeapon.call(0);
        var potions = await BDTestLib.warriorCoreInstance.getPotions.call(0);
        var intPotions = await BDTestLib.warriorCoreInstance.getIntPotions.call(0);
        assert.equal(armor.toNumber(),0,"Warrior had non-zero starting armor!");
        assert.equal(shield.toNumber(),0,"Warrior had non-zero starting shield!");
        assert.equal(weapon.toNumber(),0,"Warrior had non-zero starting weapon!");
        assert.equal(potions.toNumber(),0,"Warrior had non-zero starting potions!");
        assert.equal(intPotions.toNumber(),0,"Warrior had non-zero starting int potions!");
    });

    it("Should allow owner to buy minimal stats initially", async () => {
        await BDTestLib.warriorCoreInstance.buyStats(0,1,1,1,0);
        var str = await BDTestLib.warriorCoreInstance.getStr.call(0);
        var dex = await BDTestLib.warriorCoreInstance.getDex.call(0);
        var con = await BDTestLib.warriorCoreInstance.getCon.call(0);
        var luck = await BDTestLib.warriorCoreInstance.getLuck.call(0);
        var points = await BDTestLib.warriorCoreInstance.getPoints.call(0);
        assert.equal(str.toNumber(),6,"Warrior STR did not increase as expected!");
        assert.equal(dex.toNumber(),6,"Warrior DEX did not increase as expected!");
        assert.equal(con.toNumber(),6,"Warrior CON did not increase as expected!");
        assert.equal(luck.toNumber(),5,"Warrior LUCK did not stay constant as expected!");
        assert.equal(points.toNumber(),425,"Warrior Points did not decrease as expected!");
    });

    it("Should allow the owner to initiate 'practice'", async () => {
        await BDTestLib.warriorCoreInstance.practice(0);
        var newState = await BDTestLib.warriorCoreInstance.getState.call(0);
        assert.equal(newState.toNumber(),1,"Warrior did not enter 'Practicing' state as expected!");
    });

    it("Practice Should end after the expected duration", async () => {
        await BDTestLib.waitUntilAfter(await BDTestLib.warriorCoreInstance.getTrainingEnd.call(0));
        await BDTestLib.warriorCoreInstance.stopPracticing(0);
        var newState = await BDTestLib.warriorCoreInstance.getState.call(0);
        assert.equal(newState.toNumber(),0,"Warrior was not able to re-enter 'Idle' state after expected number of blocks of training!");
    });

    it("Should have gained some XP after practice", async () => {
        var xp = await BDTestLib.warriorCoreInstance.getXP.call(0);
        assert.isAbove(xp.toNumber(),0,"Warrior did not gain any XP!");
    });

    it("Should have gained the appropriate amount of XP after practice", async () => {
        var xp = await BDTestLib.warriorCoreInstance.getXP.call(0);
        var xpExpected = await BDTestLib.warriorCoreInstance.getXPForPractice(0);
        assert.equal(xp.toNumber(),xpExpected.toNumber(),"Warrior did not gain the expected amount of XP!");
    });

    it("Should level up after earning appropriate xp", async () => {
        var level = await BDTestLib.warriorCoreInstance.getLevel.call(0);
        var trainingNeeded = 2;
        var newLevel = level;
        for(var i=0;i<trainingNeeded;i++){
            //console.log("Iteration: "+i+" @Level:"+await BDTestLib.warriorCoreInstance.getLevel.call(0));
            await BDTestLib.warriorCoreInstance.practice(0);
            await BDTestLib.waitUntilAfter(await BDTestLib.warriorCoreInstance.getTrainingEnd.call(0));
            await BDTestLib.warriorCoreInstance.stopPracticing(0);
        }
        newLevel = await BDTestLib.warriorCoreInstance.getLevel.call(0);
        assert.isAbove(+newLevel,+level,"Warrior did not increase in level!");
    });

    it("Should allow the owner (via BattleDromeCore) to buy equipment", async () => {
        var equipCost = await BDTestLib.warriorCoreInstance.getEquipCost.call(0,5,5,5,2,2);
        await BDTestLib.warriorCoreInstance.buyEquipment(0,5,5,5,2,2,{value:equipCost});
        var armor = await BDTestLib.warriorCoreInstance.getArmor.call(0);
        assert.equal(armor.toNumber(),5,"Warrior did not receive new armor as expected!");
        var shield = await BDTestLib.warriorCoreInstance.getArmor.call(0);
        assert.equal(shield.toNumber(),5,"Warrior did not receive new shield as expected!");
        var weapon = await BDTestLib.warriorCoreInstance.getWeapon.call(0);
        assert.equal(weapon.toNumber(),5,"Warrior did not receive new weapon as expected!");
        var potions = await BDTestLib.warriorCoreInstance.getPotions.call(0);
        assert.equal(potions.toNumber(),2,"Warrior did not receive new potions as expected!");
        var intPotions = await BDTestLib.warriorCoreInstance.getIntPotions.call(0);
        assert.equal(intPotions.toNumber(),2,"Warrior did not receive new int potions as expected!");
    });

    it("Should allow practice to be faster by consuming Int Potions", async () => {
        await BDTestLib.warriorCoreInstance.practice(0);
        var newState = await BDTestLib.warriorCoreInstance.getState.call(0);
        assert.equal(newState.toNumber(),1,"Warrior did not enter 'Practicing' state as expected!");
        //TODO: Check for duration here should be appropriately smaller
        await BDTestLib.waitUntilAfter(await BDTestLib.warriorCoreInstance.getTrainingEnd.call(0));
        await BDTestLib.warriorCoreInstance.stopPracticing(0);
        var newState = await BDTestLib.warriorCoreInstance.getState.call(0);
        assert.equal(newState.toNumber(),0,"Warrior was not able to re-enter 'Idle' state after expected number of blocks of training!");
        var intPotions = await BDTestLib.warriorCoreInstance.getIntPotions.call(0);
        assert.equal(intPotions.toNumber(),1,"Warrior did not consume an int potion as expected!");
        //TODO: Check if xp went up again
    });
    
    it("Should allow a warrior to initiate teaching if idle", async () => {
        let teachingFee = "1"
        var txResult = await BDTestLib.warriorCoreInstance.startTeaching(0,web3.utils.toWei(teachingFee,"gwei"));
        var eventFound = false;
        for(var i=0; i<txResult.logs.length; i++) {
            var log = txResult.logs[i];
            if(log.event=="NewTrainer"){
                eventFound = true;
            }
        }
        assert.equal(eventFound,true,"NewTrainer Event was not emitted!");
    });

    it("Should allow training from a level stat teacher", async () => {
        await BDTestLib.warriorCoreInstance.trainWith(1,0);
        var newStateTrainee = await BDTestLib.warriorCoreInstance.getState.call(1);
        var targetBlockTrainer = await BDTestLib.warriorCoreInstance.getTrainingEnd.call(0);
        var targetBlockTrainee = await BDTestLib.warriorCoreInstance.getTrainingEnd.call(1);
        assert.equal(newStateTrainee.toNumber(),2,"Warrior did not enter 'Training' state as expected!");
        assert.equal(targetBlockTrainee.toNumber(),targetBlockTrainer.toNumber(),"Trainer and Trainee should sync up for their 'TrainingEnd' value!")
    });

    it("Should allow completion of training", async () => {
        await BDTestLib.waitUntilAfter(await BDTestLib.warriorCoreInstance.getTrainingEnd.call(1));
        await BDTestLib.warriorCoreInstance.stopTraining(1);
        var newState = await BDTestLib.warriorCoreInstance.getState(1);
        assert.equal(newState.toNumber(),0,"Trainee did not return to Idle State!");
    });

    it("Training with a balanced trainer results in STR increase", async () => {
        var str = await BDTestLib.warriorCoreInstance.getStr.call(1);
        assert.equal(str.toNumber(),6,"Strength did not increase to the expected value!");
    });

    it("Trainer should be able to stop Teaching if Not Busy", async () => {
        await BDTestLib.warriorCoreInstance.stopTeaching(0);
        var newState = await BDTestLib.warriorCoreInstance.getState(1);
        assert.equal(newState.toNumber(),0,"Trainer did not return to Idle State!");
    });

    it("Buying DEX for trainer results in DEX dominance", async () => {
        await BDTestLib.warriorCoreInstance.buyStats(0,0,1,0,0);
        var dexVal = await BDTestLib.warriorCoreInstance.getDex(0);
        var strVal = await BDTestLib.warriorCoreInstance.getStr(0);
        var conVal = await BDTestLib.warriorCoreInstance.getCon(0);
        var domStat = await BDTestLib.warriorCoreInstance.getDominantStatValue.call(0);
        assert.equal(dexVal.toNumber(),8,"Dex did not increase as expected!");
        assert.equal(domStat.toNumber(),dexVal.toNumber(),"Dominant Stat is not equal to Dex!");
        assert.notEqual(domStat.toNumber(),strVal.toNumber(),"Dominant Stat is equal to Str instead of Dex!");
        assert.notEqual(domStat.toNumber(),conVal.toNumber(),"Dominant Stat is equal to Con instead of Dex!");
    });

    it("Trainer should be able to start Teaching Again", async () => {
        let teachingFee = "1"
        var txResult = await BDTestLib.warriorCoreInstance.startTeaching(0,web3.utils.toWei(teachingFee,"gwei"));
        var eventFound = false;
        for(var i=0; i<txResult.logs.length; i++) {
            var log = txResult.logs[i];
            if(log.event=="NewTrainer"){
                eventFound = true;
            }
        }
        assert.equal(eventFound,true,"NewTrainer Event was not emitted!");
    });

    it("Training with a DEX dominant trainer results in DEX increase", async () => {
        await BDTestLib.warriorCoreInstance.trainWith(1,0);
        var newStateTrainee = await BDTestLib.warriorCoreInstance.getState.call(1);
        var targetBlockTrainer = await BDTestLib.warriorCoreInstance.getTrainingEnd.call(0);
        var targetBlockTrainee = await BDTestLib.warriorCoreInstance.getTrainingEnd.call(1);
        assert.equal(newStateTrainee.toNumber(),2,"Warrior did not enter 'Training' state as expected!");
        assert.equal(targetBlockTrainee.toNumber(),targetBlockTrainer.toNumber(),"Trainer and Trainee should sync up for their 'TrainingEnd' value!")
        await BDTestLib.waitUntilAfter(await BDTestLib.warriorCoreInstance.getTrainingEnd.call(1));
        await BDTestLib.warriorCoreInstance.stopTraining(1);
        var newState = await BDTestLib.warriorCoreInstance.getState(1);
        assert.equal(newState.toNumber(),0,"Trainee did not return to Idle State!");
        var dex = await BDTestLib.warriorCoreInstance.getDex.call(1);
        assert.equal(dex.toNumber(),6,"Dex did not increase to the expected value!");
    });

    it("Trainer should be able to stop Teaching if Not Busy (part2)", async () => {
        await BDTestLib.warriorCoreInstance.stopTeaching(0);
        var newState = await BDTestLib.warriorCoreInstance.getState(1);
        assert.equal(newState.toNumber(),0,"Trainer did not return to Idle State!");
    });

    it("Buying CON for trainer results in CON dominance", async () => {
        await BDTestLib.warriorCoreInstance.buyStats(0,0,0,2,0);
        var dexVal = await BDTestLib.warriorCoreInstance.getDex(0);
        var strVal = await BDTestLib.warriorCoreInstance.getStr(0);
        var conVal = await BDTestLib.warriorCoreInstance.getCon(0);
        var domStat = await BDTestLib.warriorCoreInstance.getDominantStatValue.call(0);
        assert.equal(conVal.toNumber(),9,"Con did not increase as expected!");
        assert.equal(domStat.toNumber(),conVal.toNumber(),"Dominant Stat is not equal to Con!");
        assert.notEqual(domStat.toNumber(),strVal.toNumber(),"Dominant Stat is equal to Str instead of Con!");
        assert.notEqual(domStat.toNumber(),dexVal.toNumber(),"Dominant Stat is equal to Dex instead of Con!");
    });

    it("Trainer should be able to start Teaching Again (part2)", async () => {
        let teachingFee = "1"
        var txResult = await BDTestLib.warriorCoreInstance.startTeaching(0,web3.utils.toWei(teachingFee,"gwei"));
        var eventFound = false;
        for(var i=0; i<txResult.logs.length; i++) {
            var log = txResult.logs[i];
            if(log.event=="NewTrainer"){
                eventFound = true;
            }
        }
        assert.equal(eventFound,true,"NewTrainer Event was not emitted!");
    });

    it("Training with a CON dominant trainer results in CON increase", async () => {
        await BDTestLib.warriorCoreInstance.trainWith(1,0);
        var newStateTrainee = await BDTestLib.warriorCoreInstance.getState.call(1);
        var targetBlockTrainer = await BDTestLib.warriorCoreInstance.getTrainingEnd.call(0);
        var targetBlockTrainee = await BDTestLib.warriorCoreInstance.getTrainingEnd.call(1);
        assert.equal(newStateTrainee.toNumber(),2,"Warrior did not enter 'Training' state as expected!");
        assert.equal(targetBlockTrainee.toNumber(),targetBlockTrainer.toNumber(),"Trainer and Trainee should sync up for their 'TrainingEnd' value!")
        await BDTestLib.waitUntilAfter(await BDTestLib.warriorCoreInstance.getTrainingEnd.call(1));
        await BDTestLib.warriorCoreInstance.stopTraining(1);
        var newState = await BDTestLib.warriorCoreInstance.getState(1);
        assert.equal(newState.toNumber(),0,"Trainee did not return to Idle State!");
        var con = await BDTestLib.warriorCoreInstance.getCon.call(1);
        assert.equal(con.toNumber(),6,"Con did not increase to the expected value!");
        await BDTestLib.warriorCoreInstance.stopTeaching(0);
    });

});