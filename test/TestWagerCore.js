var EventCore = artifacts.require("EventCore.sol");
var WarriorCore = artifacts.require("WarriorCore.sol");
var WagerCore = artifacts.require("WagerCore.sol");

contract('WagerCore', function(accounts) {
    var BDTestLib = require('./BDTestLib.js')

    var joe;
    var bob;
    var steve;
    var mike;
    var jeff;
    var dave;
    var eventA;
    var eventB;
    var playerA = 0;
    var playerB = 1;
    var playerC = 2;
    var playerD = 3;
    var playerE = 4;
    var playerF = 5;
    var playerG = 6;
    var playerH = 7;
    var playerI = 8;
    var playerJ = 9;
    var joeOwner = playerJ;
    var bobOwner = playerI;
    var steveOwner = playerH;
    var mikeOwner = playerJ;
    var jeffOwner = playerI;
    var daveOwner = playerH;

    before(async () => {
        console.log("   Pre-Test Initialization:")
        //Check deployed instances
        console.log("       Initializing Deployed Instances...")
        warriorInstance = await WarriorCore.deployed();
        eventInstance = await EventCore.deployed();
        wagerInstance = await WagerCore.deployed();

        //Setup test library
        console.log("       Initializing BDTestLib Testing Harness...")
        BDTestLib.init(accounts,eventInstance,warriorInstance,wagerInstance,null)

        //Check Library Setup
        console.log("       Verifying BDTestLib Testing Harness Initialization...")
        assert.isNotNull(BDTestLib.warriorCoreInstance,"Warrior Core Instance was Null!");
        assert.isNotNull(BDTestLib.eventCoreInstance,"Event Core Instance was Null!");
        assert.isNotNull(BDTestLib.wagerCoreInstance,"Wager Core Instance was Null!");

        //Generate Some Events
        console.log("       Generating Initial Events...")
        eventA = await BDTestLib.createEvent(playerF, 2, 4, 0, 1, 4, 10);
        eventB = await BDTestLib.createEvent(playerG, 2, 4, 0, 1, 4, 10);

        //Generate Some Warriors
        console.log("       Creating Initial Warriors...")
        joe = await BDTestLib.createWarrior(joeOwner, "Joe", 0, 0, 0, 0);
        bob = await BDTestLib.createWarrior(bobOwner, "Bob", 0, 0, 0, 0);
        steve = await BDTestLib.createWarrior(steveOwner, "Steve", 0, 0, 0, 0);
        mike = await BDTestLib.createWarrior(mikeOwner, "Mike", 0, 0, 0, 0);
        jeff = await BDTestLib.createWarrior(jeffOwner, "Jeff", 0, 0, 0, 0);
        dave = await BDTestLib.createWarrior(daveOwner, "Dave", 0, 0, 0, 0);

        //Have Some Warriors Join the Events
        console.log("       Joining Warriors to Events...")
        await BDTestLib.warriorJoinEvent(joeOwner, eventA, joe);
        await BDTestLib.warriorJoinEvent(bobOwner, eventA, bob);
        await BDTestLib.warriorJoinEvent(steveOwner, eventA, steve);
        await BDTestLib.warriorJoinEvent(mikeOwner, eventB, mike);
        await BDTestLib.warriorJoinEvent(jeffOwner, eventB, jeff);
        await BDTestLib.warriorJoinEvent(daveOwner, eventB, dave);

        console.log("   Pre-Test Initialization Complete!")
    });
    
    it("Should be owned by first account", async () => {
        var owner = await BDTestLib.wagerCoreInstance.owner.call();
        assert.equal(owner, accounts[0], "Didn't have the right owner account!");
    });

    it("Should have correct Event Core", async () => {
        var storedECAddress = await BDTestLib.wagerCoreInstance.eventCore.call();
        var deployedECAddress = BDTestLib.eventCoreInstance.address;
        assert.equal(storedECAddress, deployedECAddress, "Didn't have the right EventCore address!");
    });

    it("Should have correct Warrior Core", async () => {
        var storedWCAddress = await BDTestLib.wagerCoreInstance.warriorCore.call();
        var deployedWCAddress = BDTestLib.warriorCoreInstance.address;
        assert.equal(storedWCAddress, deployedWCAddress, "Didn't have the right WarriorCore address!");
    });

    it("Should have no initial wager pool on an event", async () => {
        var currentPool = await BDTestLib.wagerCoreInstance.getEventTotalWagerPool.call(eventA);
        assert.equal(+currentPool,0,"The Event ID:"+eventA+" Started with Wager Pool! WTF?!");
    });

    it("Should have no initial wager count on an event", async () => {
        var wagerCount = await BDTestLib.wagerCoreInstance.getWagerCount.call(eventA);
        assert.equal(+wagerCount,0,"The Event ID:"+eventA+" Started with Wagers! WTF?!");
    });

    it("Should Not Allow Placing a Wager on a non existing Event", async () => {
        var eventID = 10;
        var warriorID = joe;
        var wagerGwei = "2500000";
        var wagerAmount = web3.utils.toWei(wagerGwei,"gwei");
        var txResult = await BDTestLib.wagerCoreInstance.canWager.call(wagerAmount,warriorID,eventID);
        assert.isFalse(txResult, "Wager was allowed for "+wagerGwei+" Gwei, on Event:"+eventID+" on Warrior:"+warriorID+"! (when it shouldn't be!)");
    });
    
    it("Should Not Allow Placing a Wager on a non existing Warrior", async () => {
        var eventID = eventA;
        var warriorID = 10;
        var wagerGwei = "2500000";
        var wagerAmount = web3.utils.toWei(wagerGwei,"gwei");
        var txResult = await BDTestLib.wagerCoreInstance.canWager.call(wagerAmount,warriorID,eventID);
        assert.isFalse(txResult, "Wager was allowed for "+wagerGwei+" Gwei, on Event:"+eventID+" on Warrior:"+warriorID+"! (when it shouldn't be!)");
    });
    
    it("Should Not Allow Placing a Wager on a Valid Warrior who is not participating in a Valid Event", async () => {
        var eventID = eventA;
        var warriorID = mike;
        var wagerGwei = "2500000";
        var wagerAmount = web3.utils.toWei(wagerGwei,"gwei");
        var txResult = await BDTestLib.wagerCoreInstance.canWager.call(wagerAmount,warriorID,eventID);
        assert.isFalse(txResult, "Wager was allowed for "+wagerGwei+" Gwei, on Event:"+eventID+" on Warrior:"+warriorID+"! (when it shouldn't be!)");
    });

    it("Should Not Allow Placing a Wager on a valid Warrior in a valid Event with a tiny amount", async () => {
        var eventID = eventA;
        var warriorID = joe;
        var tinyWager = "99999";
        var wagerAmount = web3.utils.toWei(tinyWager,"gwei");
        var txResult = await BDTestLib.wagerCoreInstance.canWager.call(wagerAmount,warriorID,eventID);
        assert.isFalse(txResult, "Wager was allowed for "+tinyWager+" Szabo, on Event:"+eventID+" on Warrior:"+warriorID+"! (when it shouldn't be!)");
    });

    it("Should Allow Placing a Wager on a valid Warrior in an Event", async () => {
        var eventID = eventA;
        var warriorID = joe;
        var wagerGwei = "1000000";
        var wagerAmount = web3.utils.toWei(wagerGwei,"gwei");
        var txResult = await BDTestLib.wagerCoreInstance.canWager.call(wagerAmount,warriorID,eventID);
        assert.isTrue(txResult, "Wager not allowed for "+wagerGwei+" Gwei, on Event:"+eventID+" on Warrior:"+warriorID+"!");
    });

    it("Should Actually Place the Wager when a transaction is submitted with the wager() call", async () => {
        var eventID = eventA;
        var warriorID = joe;
        var wagerGwei = "1000000";
        var player = playerA;
        var wagerAmount = web3.utils.toWei(wagerGwei,"gwei");
        await BDTestLib.placeWager(player,eventID,warriorID,wagerAmount);
    });

    it("Should Calculate the Winner and Warrior Pools Correctly", async () => {
        var eventID = eventA;
        var newPool = await BDTestLib.wagerCoreInstance.getEventTotalWagerPool.call(eventID);
        var warriorPool = await BDTestLib.wagerCoreInstance.getEventWinningWarriorPool.call(eventID);
        var winnerPool = await BDTestLib.wagerCoreInstance.getEventWinningWagerPool.call(eventID);
        var expectedWarriorDivisor = 10;
        var expectedWarriorPool = newPool/expectedWarriorDivisor;
        var expectedWinnerPool = newPool-expectedWarriorPool;
        assert.equal(+warriorPool,+expectedWarriorPool,"The Warrior Pool was not accurate!");
        assert.equal(+winnerPool,+expectedWinnerPool,"The Winner Pool was not accurate!");
    });

    it("Should Not Allow Placing a Second Wager on the same event for a different warrior (from the same account)", async () => {
        var eventID = eventA;
        var warriorID = bob;
        var wagerGwei = "2500000";
        var player = playerA;
        var caller = accounts[player]
        var wagerAmount = web3.utils.toWei(wagerGwei,"gwei");
        var txResult = await BDTestLib.wagerCoreInstance.canWager.call(wagerAmount,warriorID,eventID,{from:caller});
        assert.isFalse(txResult, "Wager was allowed for "+wagerGwei+" Gwei, on Event:"+eventID+" on Warrior:"+warriorID+"! (when it shouldn't be!)");
    });

    it("Should Allow Placing a Second Wager on the same event for the same warrior (from the same account)", async () => {
        var eventID = eventA;
        var warriorID = joe;
        var wagerGwei = "2500000";
        var player = playerA;
        var caller = accounts[player]
        var wagerAmount = web3.utils.toWei(wagerGwei,"gwei");
        var txResult = await BDTestLib.wagerCoreInstance.canWager.call(wagerAmount,warriorID,eventID,{from:caller});
        assert.isTrue(txResult, "Update Wager was not allowed for "+wagerGwei+" Gwei, on Event:"+eventID+" on Warrior:"+warriorID+"!");
    });
    
    it("Should Allow Placing a Second Wager on the same event for the same warrior (from a different account)", async () => {
        var eventID = eventA;
        var warriorID = joe;
        var wagerGwei = "1000000";
        var player = playerB;
        var caller = accounts[player]
        var wagerAmount = web3.utils.toWei(wagerGwei,"gwei");
        var txResult = await BDTestLib.wagerCoreInstance.canWager.call(wagerAmount,warriorID,eventID,{from:caller});
        assert.isTrue(txResult, "Update Wager was not allowed for "+wagerGwei+" Gwei, on Event:"+eventID+" on Warrior:"+warriorID+"!");
    });

    it("Should Place a Second Wager Correctly on the same event, for the same warrior, from a different account", async () => {
        var eventID = eventA;
        var warriorID = joe;
        var wagerGwei = "1000000";
        var player = playerB;
        var wagerAmount = web3.utils.toWei(wagerGwei,"gwei");
        await BDTestLib.placeWager(player,eventID,warriorID,wagerAmount);
    });

    it("Should have correct wager details from the first and second wager from both players respectively", async () => {
        var eventID = eventA;
        var warriorID = joe;
        var wagerGwei = "1000000";
        var callerA = accounts[playerA]
        var callerB = accounts[playerB]
        var wagerAmount = web3.utils.toWei(wagerGwei,"gwei");
        var wagerIDA = await BDTestLib.wagerCoreInstance.getWagerIDByOwner.call(eventID,callerA);
        var wagerIDB = await BDTestLib.wagerCoreInstance.getWagerIDByOwner.call(eventID,callerB);
        var wagerWarriorA = await BDTestLib.wagerCoreInstance.getWagerWarrior.call(eventID,wagerIDA);
        var wagerWarriorB = await BDTestLib.wagerCoreInstance.getWagerWarrior.call(eventID,wagerIDB);
        var wagerAmountA = await BDTestLib.wagerCoreInstance.getWagerAmount.call(eventID,wagerIDA);
        var wagerAmountB = await BDTestLib.wagerCoreInstance.getWagerAmount.call(eventID,wagerIDB);
        assert.equal(+wagerAmount,+wagerAmountA,"The Wager from PlayerA did not have the correct Amount!");
        assert.equal(+wagerAmount,+wagerAmountB,"The Wager from PlayerB did not have the correct Amount!");
        assert.equal(+warriorID,+wagerWarriorA,"The Wager from PlayerA did not have the correct Warrior!");
        assert.equal(+warriorID,+wagerWarriorB,"The Wager from PlayerB did not have the correct Warrior!");
    });

    it("Should Place a Third Wager Correctly on the same event, for the same warrior, from the first account", async () => {
        var eventID = eventA;
        var warriorID = joe;
        var wagerGwei = "1000000";
        var player = playerA;
        var wagerAmount = web3.utils.toWei(wagerGwei,"gwei");
        await BDTestLib.placeWager(player,eventID,warriorID,wagerAmount);
    });

    it("Should Allow Placing a Fourth Wager on another event for a different warrior (from a third account)", async () => {
        var eventID = eventA;
        var warriorID = bob;
        var wagerGwei = "2500000";
        var player = playerC;
        var caller = accounts[player]
        var wagerAmount = web3.utils.toWei(wagerGwei,"gwei");
        var txResult = await BDTestLib.wagerCoreInstance.canWager.call(wagerAmount,warriorID,eventID,{from:caller});
        assert.isTrue(txResult, "Update Wager was not allowed for "+wagerGwei+" Gwei, on Event:"+eventID+" on Warrior:"+warriorID+"!");
    });

    it("Should Place a Fourth Wager Correctly on the same event, for a different warrior, from a third account", async () => {
        var eventID = eventA;
        var warriorID = bob;
        var wagerGwei = "2500000";
        var player = playerC;
        var wagerAmount = web3.utils.toWei(wagerGwei,"gwei");
        await BDTestLib.placeWager(player,eventID,warriorID,wagerAmount);
    });

    it("Should Place a Fifth Wager Correctly on the same event, same warrior and account as the Third", async () => {
        var eventID = eventA;
        var warriorID = joe;
        var wagerGwei = "1000000";
        var player = playerB;
        var wagerAmount = web3.utils.toWei(wagerGwei,"gwei");
        await BDTestLib.placeWager(player,eventID,warriorID,wagerAmount);
    });
    
    it("Should NOT allow calculation of winners since event is not yet complete", async () => {
        var eventID = eventA;
        var txResult = await BDTestLib.wagerCoreInstance.canCalculateWinners.call(eventID);
        assert.isFalse(txResult, "Winner Calculation was Allowed on Event:"+eventID+" (When it shouldn't be)!");
    });

    it("Should allow the event run to completion", async () => {
        var eventID = eventA;
        var playerX = playerD;
        var playerY = playerE;
        await BDTestLib.startEvent(playerX, eventID);
        await BDTestLib.runEventToCompletion(playerX, playerY, eventID);
    });

    it("Should allow calculation of winners now that event is complete", async () => {
        var eventID = eventA;
        var txResult = await BDTestLib.wagerCoreInstance.canCalculateWinners.call(eventID);
        assert.isTrue(txResult, "Winner Calculation was not Allowed on Event:"+eventID+"!");
    });

    it("Should NOT allow payout of winners since they are not calculated", async () => {
        var eventID = eventA;
        var txResult = await BDTestLib.wagerCoreInstance.canPayWinners.call(eventID);
        assert.isFalse(txResult, "Winner Pay Out was Allowed on Event:"+eventID+" (When it shouldn't be)!");
    });

    it("Should correctly calculate winners", async () => {
        var eventID = eventA;
        var txResult = await BDTestLib.wagerCoreInstance.calculateWinners(eventID);
        var eventFound = false;
        for(var i=0; i<txResult.logs.length; i++) {
            var log = txResult.logs[i];
            if(log.event=="WinnersCalculated"){
                eventFound = true;
            }
        }
        assert.isTrue(eventFound,"The WinnersCalculated Event was not detected!");
    });

    it("Should allow the payout of winners now that they are calculated", async () => {
        var eventID = eventA;
        var txResult = await BDTestLib.wagerCoreInstance.canPayWinners.call(eventID);
        assert.isTrue(txResult, "Winner Pay Out was not Allowed on Event:"+eventID+"!");
    });

    it("Should correctly payout winners", async () => {
        var eventID = eventA;
        var eventFound = false;
        var eventHasWinner = await BDTestLib.eventCoreInstance.hasWinner.call(eventID);
        var eventWinnerID = (await BDTestLib.eventCoreInstance.getWinner.call(eventID)).toNumber();
        var eventWinnerOldBalance = await BDTestLib.warriorCoreInstance.getBalance.call(eventWinnerID);
        var eventWinnerOwner = await BDTestLib.warriorCoreInstance.getOwner.call(eventWinnerID);
        var eventWinnerOwnerOldBalance = await web3.eth.getBalance(eventWinnerOwner);
        var winnerCount = await BDTestLib.wagerCoreInstance.getWinnerCount.call(eventID);
        var winnerOldBalances = [];
        for(var i=0; i<winnerCount; i++){
            var winnerAddress = await BDTestLib.wagerCoreInstance.getWinningWagerOwner.call(eventID,i);
            winnerOldBalances[i] = await web3.eth.getBalance(winnerAddress);
        }
        var txResult = await BDTestLib.wagerCoreInstance.payWinners(eventID);
        for(var i=0; i<txResult.logs.length; i++) {
            var log = txResult.logs[i];
            if(log.event=="PaymentTriggered"){
                eventFound = true;
            }
        }
        assert.isTrue(eventFound,"The PaymentTriggered Event was not detected!");
        var eventWinnerNewBalance = await BDTestLib.warriorCoreInstance.getBalance.call(eventWinnerID);
        var eventWinnerOwnerNewBalance = await web3.eth.getBalance(eventWinnerOwner);
        if(eventHasWinner){
            //Winning warrior should get his share
            console.log("Has Winning Warrior...");
            assert.isAbove(+eventWinnerNewBalance,+eventWinnerOldBalance,"The Winning Warrior's Balance did not Increase!");
            assert.isAbove(+eventWinnerOwnerNewBalance,+eventWinnerOwnerOldBalance,"The Winning Warrior Owner's Balance did not Increase (tax)!");
        }else{
            //No warrior won, so at least one donation should occur:
            console.log("No Winning Warrior...");
            var donateFound = false;
            for(var i=0; i<txResult.logs.length; i++) {
                var log = txResult.logs[i];
                if(log.event=="HouseDonation"){
                    donateFound = true;
                }
            }
            assert.isTrue(donateFound,"Donation Event not Found (no warrior won)!")
        }
        //If there's winners, check they got paid!
        var winnerPortion = 0;
        if(winnerCount>0) {
            console.log("Has "+winnerCount+" Winning Wager(s)!");
            winnerPortion = await BDTestLib.wagerCoreInstance.getWinnerPortion.call(eventID);
        }
        for(var i=0; i<winnerCount; i++){
            var winnerAddress = await BDTestLib.wagerCoreInstance.getWinningWagerOwner.call(eventID,i);
            var winnerAmount = await BDTestLib.wagerCoreInstance.getWinningWagerAmount.call(eventID,i);
            var winningWagerID = (await BDTestLib.wagerCoreInstance.getWagerIDByOwner.call(eventID,winnerAddress)).toNumber();
            var newBalance = await web3.eth.getBalance(winnerAddress).valueOf();
            var paymentAmount = 0;
            var winnerEventFound = false;
            for(var x=0; x<txResult.logs.length; x++) {
                var log = txResult.logs[x];
                if(log.event=="WinnerPaid" && log.args.winner==winnerAddress){
                    winnerEventFound = true;
                    paymentAmount = +log.args.amount.valueOf();
                }
            }
            var expectedPayment = (+winnerPortion * +winnerAmount) + +winnerAmount;
            assert.isTrue(winnerEventFound,"Appropriate WinnerPaid Event for Wager ID:"+winningWagerID+" Winner #"+i+": "+winnerAddress+" was not found!")
            assert.equal(+paymentAmount,+expectedPayment,"Wager Wager ID:"+winningWagerID+" Winner #"+i+": "+winnerAddress+" payout wasn't for the expected amount!");
            assert.isAbove(+newBalance,+winnerOldBalances[i],"Wager Wager ID:"+winningWagerID+" Winner #"+i+": "+winnerAddress+" Did not gain any balance from payout!");
        }
        if(!eventHasWinner && winnerCount==0){
            //No winners at all, so donate!
            console.log("No Winner Either...");
            var donateFound = false;
            for(var i=0; i<txResult.logs.length; i++) {
                var log = txResult.logs[i];
                if(log.event=="HouseDonation"){
                    donateFound = true;
                }
            }
            assert.isTrue(donateFound,"Donation Event not Found (no winner)!")
        }
    });

});