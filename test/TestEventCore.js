var EventCore = artifacts.require("EventCore.sol");
var WarriorCore = artifacts.require("WarriorCore.sol");

contract('EventCore', function (accounts) {
    var BDTestLib = require('./BDTestLib.js')

    var a_joe;
    var a_bob;
    var a_steve;
    var a_mike;
    var b_joe;
    var b_bob;
    var b_steve;
    var b_mike;
    var c_joe;
    var c_bob;
    var c_steve;
    var c_mike;
    var d_joe;
    var d_bob;
    var d_steve;
    var d_mike;
    var e_joe;
    var e_bob;
    var e_steve;
    var e_mike;
    var f_joe;
    var f_bob;
    var f_steve;
    var f_mike;

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
    var primaryOwner = playerI;
    var secondaryOwner = playerJ;

    before(async () => {
        console.log("   Pre-Test Initialization:")
        //Check deployed instances
        console.log("       Initializing Deployed Instances...")
        warriorInstance = await WarriorCore.deployed();
        eventInstance = await EventCore.deployed();

        //Setup test library
        console.log("       Initializing BDTestLib Testing Harness...")
        BDTestLib.init(accounts, eventInstance, warriorInstance, null, null)

        //Check Library Setup
        console.log("       Verifying BDTestLib Testing Harness Initialization...")
        assert.isNotNull(BDTestLib.warriorCoreInstance, "Warrior Core Instance was Null!");
        assert.isNotNull(BDTestLib.eventCoreInstance, "Event Core Instance was Null!");

        //Generate Some Warriors
        console.log("       Creating Initial Warriors...")
        a_joe = await BDTestLib.createWarrior(primaryOwner, "A Joe", 0, 0, 0, 0);
        a_bob = await BDTestLib.createWarrior(primaryOwner, "A Bob", 0, 0, 0, 0);
        a_steve = await BDTestLib.createWarrior(primaryOwner, "A Steve", 0, 0, 0, 0);
        a_mike = await BDTestLib.createWarrior(primaryOwner, "A Mike", 0, 0, 0, 0);
        b_joe = await BDTestLib.createWarrior(primaryOwner, "B Joe", 0, 0, 1, 0);
        b_bob = await BDTestLib.createWarrior(primaryOwner, "B Bob", 0, 0, 0, 1);
        b_steve = await BDTestLib.createWarrior(primaryOwner, "B Steve", 0, 0, 1, 1);
        b_mike = await BDTestLib.createWarrior(primaryOwner, "B Mike", 0, 0, 0, 2);
        c_joe = await BDTestLib.createWarrior(primaryOwner, "C Joe", 0, 0, 1, 3);
        c_bob = await BDTestLib.createWarrior(primaryOwner, "C Bob", 0, 0, 1, 4);
        c_steve = await BDTestLib.createWarrior(primaryOwner, "C Steve", 0, 1, 0, 5);
        c_mike = await BDTestLib.createWarrior(primaryOwner, "C Mike", 0, 0, 1, 6);
        d_joe = await BDTestLib.createWarrior(primaryOwner, "D Joe", 0, 1, 0, 7);
        d_bob = await BDTestLib.createWarrior(primaryOwner, "D Bob", 1, 0, 0, 8);
        d_steve = await BDTestLib.createWarrior(primaryOwner, "D Steve", 1, 1, 0, 9);
        d_mike = await BDTestLib.createWarrior(primaryOwner, "D Mike", 1, 0, 1, 0);
        e_joe = await BDTestLib.createWarrior(primaryOwner, "E Joe", 1, 1, 1, 1);
        e_bob = await BDTestLib.createWarrior(primaryOwner, "E Bob", 2, 0, 2, 2);
        e_steve = await BDTestLib.createWarrior(primaryOwner, "E Steve", 0, 2, 0, 3);
        e_mike = await BDTestLib.createWarrior(primaryOwner, "E Mike", 0, 2, 2, 4);
        f_joe = await BDTestLib.createWarrior(primaryOwner, "F Joe", 2, 2, 0, 5);
        f_bob = await BDTestLib.createWarrior(primaryOwner, "F Bob", 0, 2, 0, 6);
        f_steve = await BDTestLib.createWarrior(primaryOwner, "F Steve", 2, 0, 2, 7);
        f_mike = await BDTestLib.createWarrior(primaryOwner, "F Mike", 0, 0, 2, 8);

        console.log("   Pre-Test Initialization Complete!")
    });

    it("Should start with zero events", async () => {
        var roundCount = await BDTestLib.eventCoreInstance.getEventCount.call();
        assert.equal(roundCount, 0, "The EventCore did not start with 0 rounds!");
    });

    it("Should allow for reasonable event creation fee", async () => {
        let maxCost = "750000000" // 0.75 ETH
        var eventFee = await BDTestLib.eventCoreInstance.getNewEventFee.call(5, 10);
        assert.isBelow(+eventFee.valueOf(), +web3.utils.toWei(maxCost, "gwei").valueOf(), "The minimum cost of a new event is too high!");
    });

    it("Should allow user to create the first event", async () => {
        await BDTestLib.createEvent(0, 2, 4, 0, 1, 4, 10);
    });

    it("New Event should have zero participants to start", async () => {
        var count = await BDTestLib.eventCoreInstance.getParticipantCount.call(0);
        assert.equal(count, 0, "The event started off with non-zero participant count!");
    });

    it("New Event should allow participants of appropriate level", async () => {
        var result = await BDTestLib.eventCoreInstance.canAddParticipant.call(0, 1);
        assert.equal(result, true, "The event does not allow participants of level 1!");
    });

    it("New Event should NOT allow participants of too high level", async () => {
        var result = await BDTestLib.eventCoreInstance.canAddParticipant.call(0, 20);
        assert.equal(result, false, "The event allows participants of level 10!");
    });

    //it("New Event should NOT allow participants of too low level", async () => {
    //    var result = await BDTestLib.eventCoreInstance.canAddParticipant.call(0,0);
    //    assert.equal(result,false,"The event allows participants of level 0!");
    //});
    //TODO: FIX

    it("Should Allow 4 new warriors to Join the First Event", async () => {
        await BDTestLib.warriorJoinEvent(primaryOwner, 0, a_joe);
        await BDTestLib.warriorJoinEvent(primaryOwner, 0, a_bob);
        await BDTestLib.warriorJoinEvent(primaryOwner, 0, a_steve);
        await BDTestLib.warriorJoinEvent(primaryOwner, 0, a_mike);
    });

    it("Should Allow The First Event to Start", async () => {
        await BDTestLib.startEvent(0, 0);
    });

    it("Should Allow The Event to be Polled Repeatedly (for a reasonable amount of gas)", async () => {
        await BDTestLib.runEventToCompletion(0, 1, 0);
    });

    it("Should show that the owner of the first event no longer has an active event", async () => {
        var hasCurrent = await BDTestLib.eventCoreInstance.hasCurrentEvent.call(accounts[0]);
        assert.isFalse(hasCurrent, "hasCurrentEvent() returned true but the event should be over!");
    });

    it("Should allow the owner of the first event to create a new event", async () => {
        var canCreate = await BDTestLib.eventCoreInstance.canCreateEvent.call(5, { from: accounts[0] });
        assert.isTrue(canCreate, "canCreateEvent() returned false!");
    });

    it("Should allow another user to create another event after the first", async () => {
        var canCreate = await BDTestLib.eventCoreInstance.canCreateEvent.call(5, { from: accounts[1] });
        assert.isTrue(canCreate, "canCreateEvent() returned false!");
    });

    it("Should allow the creation of another new event, 4 warriors to join, and polling to completion with unclaimed balance.", async () => {
        var ownerAccount = playerB;
        var secondEvent = await BDTestLib.createEvent(ownerAccount, 2, 4, 0, 1, 1, 10);
        await BDTestLib.warriorJoinEvent(primaryOwner, secondEvent, b_joe);
        await BDTestLib.warriorJoinEvent(primaryOwner, secondEvent, b_bob);
        await BDTestLib.warriorJoinEvent(primaryOwner, secondEvent, b_steve);
        await BDTestLib.warriorJoinEvent(primaryOwner, secondEvent, b_mike);
        await BDTestLib.startEvent(ownerAccount, secondEvent);
        await BDTestLib.runEventToCompletion(ownerAccount + 1, ownerAccount + 2, secondEvent);
        let unclaimedWei = await BDTestLib.eventCoreInstance.getUnclaimedPool.call();
        let unclaimedGwei = web3.utils.fromWei(unclaimedWei, "gwei")
        assert.isAbove(+unclaimedGwei.valueOf(), 0, "Unclaimed pool didn't increase!");
    });

    it("Should allow the creation of a third event (which should receive some unclaimed pool)", async () => {
        var ownerAccount = playerA;
        var eventFee = await BDTestLib.eventCoreInstance.getNewEventFee.call(4, 1);
        var thirdEvent = await BDTestLib.createEvent(ownerAccount, 2, 4, 0, 1, 1, 10);
        var eventBalance = await BDTestLib.eventCoreInstance.getBalance.call(thirdEvent);
        var eventFeeGwei = parseFloat(web3.utils.fromWei(eventFee, "gwei"));
        var eventBalanceGwei = parseFloat(web3.utils.fromWei(eventBalance, "gwei"));
        assert.isAbove(eventBalanceGwei, eventFeeGwei, "The event did not have the extra boosted prize pool as expected!");
    });

    it("Should not allow the previous user to create another event with a still active event", async () => {
        var canCreate = await BDTestLib.eventCoreInstance.canCreateEvent.call(2);
        assert.isFalse(canCreate, "canCreateEvent() returned true!");
    });

    it("Should allow the creation/joining and running of a 4th event (stress testing event creation system)", async () => {
        var ownerAccount = playerF;
        var stressEvent = await BDTestLib.createEvent(ownerAccount, 2, 4, 0, 1, 5, 10);
        await BDTestLib.warriorJoinEvent(primaryOwner, stressEvent, c_joe);
        await BDTestLib.warriorJoinEvent(primaryOwner, stressEvent, c_bob);
        await BDTestLib.warriorJoinEvent(primaryOwner, stressEvent, c_steve);
        await BDTestLib.warriorJoinEvent(primaryOwner, stressEvent, c_mike);
        await BDTestLib.startEvent(ownerAccount, stressEvent);
        await BDTestLib.runEventToCompletion(ownerAccount + 1, ownerAccount + 2, stressEvent);
    });

    it("Should allow the creation/joining and running of a 5th event (stress testing event creation system)", async () => {
        var ownerAccount = playerG;
        var stressEvent = await BDTestLib.createEvent(ownerAccount, 2, 4, 0, 1, 5, 10);
        await BDTestLib.warriorJoinEvent(primaryOwner, stressEvent, d_joe);
        await BDTestLib.warriorJoinEvent(primaryOwner, stressEvent, d_bob);
        await BDTestLib.warriorJoinEvent(primaryOwner, stressEvent, d_steve);
        await BDTestLib.warriorJoinEvent(primaryOwner, stressEvent, d_mike);
        await BDTestLib.startEvent(ownerAccount, stressEvent);
        await BDTestLib.runEventToCompletion(ownerAccount + 1, ownerAccount + 2, stressEvent);
    });

    it("Should allow the creation/joining and running of a large event (stress testing event creation system)", async () => {
        var ownerAccount = playerH;
        var stressEvent = await BDTestLib.createEvent(ownerAccount, 2, 8, 0, 1, 5, 10);
        await BDTestLib.warriorJoinEvent(primaryOwner, stressEvent, e_joe);
        await BDTestLib.warriorJoinEvent(primaryOwner, stressEvent, e_bob);
        await BDTestLib.warriorJoinEvent(primaryOwner, stressEvent, e_steve);
        await BDTestLib.warriorJoinEvent(primaryOwner, stressEvent, e_mike);
        await BDTestLib.warriorJoinEvent(primaryOwner, stressEvent, f_joe);
        await BDTestLib.warriorJoinEvent(primaryOwner, stressEvent, f_bob);
        await BDTestLib.warriorJoinEvent(primaryOwner, stressEvent, f_steve);
        await BDTestLib.warriorJoinEvent(primaryOwner, stressEvent, f_mike);
        await BDTestLib.startEvent(ownerAccount, stressEvent);
        await BDTestLib.runEventToCompletion(ownerAccount + 1, ownerAccount + 2, stressEvent);
    });

    it("Average Profit of a Poller across all previous tests should be reasonable", async () => {
        let avgPollMargin = BDTestLib.pollerTotalProfit / BDTestLib.pollerTotalCount
        let pollMarginTarget = 1
        assert.isAtLeast(avgPollMargin, pollMarginTarget, "Average Profit to a Poller was not at least " + pollMarginTarget + " Gwei!")
        console.log("FYI: Average Poller Margin Was:" + avgPollMargin + " Gwei!")
    });

    //Commenting out these tests as they fail due to known bug surrounding RNG.
    /*
    it("Should allow combat to succeed with one warrior equipped with a Levelled Up Sword vs an Un-Armed Opponent", async () => {
        var ownerAccount = 20;
        var equipmentTestEvent = await BDTestLib.createEvent(ownerAccount, 2, 4, 0, 5, 10, 10);
        var warriorEquippedA = await BDTestLib.createWarrior(ownerAccount, "Sword Test A", 0, 0, 0, 0, 0, 0, 2, 0);
        var warriorEquippedB = await BDTestLib.createWarrior(ownerAccount, "Sword Test B", 0, 0, 0, 0, 0, 0, 0, 0);
        await BDTestLib.warriorJoinEvent(ownerAccount, equipmentTestEvent, warriorEquippedA);
        await BDTestLib.warriorJoinEvent(ownerAccount, equipmentTestEvent, warriorEquippedB);
        await BDTestLib.startEvent(ownerAccount, equipmentTestEvent);
        await BDTestLib.runEventToCompletion(ownerAccount + 1, ownerAccount + 2, equipmentTestEvent);
    });

    it("Should allow combat to succeed with one warrior equipped with a Levelled Up Falchion vs an Un-Armed Opponent", async () => {
        var ownerAccount = 21;
        var equipmentTestEvent = await BDTestLib.createEvent(ownerAccount, 2, 4, 0, 5, 10, 10);
        var warriorEquippedA = await BDTestLib.createWarrior(ownerAccount, "Falchion Test A", 0, 0, 0, 1, 0, 0, 2, 0);
        var warriorEquippedB = await BDTestLib.createWarrior(ownerAccount, "Falchion Test B", 0, 0, 0, 0, 0, 0, 0, 0);
        await BDTestLib.warriorJoinEvent(ownerAccount, equipmentTestEvent, warriorEquippedA);
        await BDTestLib.warriorJoinEvent(ownerAccount, equipmentTestEvent, warriorEquippedB);
        await BDTestLib.startEvent(ownerAccount, equipmentTestEvent);
        await BDTestLib.runEventToCompletion(ownerAccount + 1, ownerAccount + 2, equipmentTestEvent);
    });

    it("Should allow combat to succeed with one warrior equipped with a Levelled Up Broadsword vs an Un-Armed Opponent", async () => {
        var ownerAccount = 22;
        var equipmentTestEvent = await BDTestLib.createEvent(ownerAccount, 2, 4, 0, 5, 10, 10);
        var warriorEquippedA = await BDTestLib.createWarrior(ownerAccount, "Broadsword Test A", 0, 0, 0, 2, 0, 0, 2, 0);
        var warriorEquippedB = await BDTestLib.createWarrior(ownerAccount, "Broadsword Test B", 0, 0, 0, 0, 0, 0, 0, 0);
        await BDTestLib.warriorJoinEvent(ownerAccount, equipmentTestEvent, warriorEquippedA);
        await BDTestLib.warriorJoinEvent(ownerAccount, equipmentTestEvent, warriorEquippedB);
        await BDTestLib.startEvent(ownerAccount, equipmentTestEvent);
        await BDTestLib.runEventToCompletion(ownerAccount + 1, ownerAccount + 2, equipmentTestEvent);
    });

    it("Should allow combat to succeed with one warrior equipped with a Levelled Up Axe vs an Un-Armed Opponent", async () => {
        var ownerAccount = 23;
        var equipmentTestEvent = await BDTestLib.createEvent(ownerAccount, 2, 4, 0, 5, 10, 10);
        var warriorEquippedA = await BDTestLib.createWarrior(ownerAccount, "Axe Test A", 0, 0, 0, 3, 0, 0, 2, 0);
        var warriorEquippedB = await BDTestLib.createWarrior(ownerAccount, "Axe Test B", 0, 0, 0, 0, 0, 0, 0, 0);
        await BDTestLib.warriorJoinEvent(ownerAccount, equipmentTestEvent, warriorEquippedA);
        await BDTestLib.warriorJoinEvent(ownerAccount, equipmentTestEvent, warriorEquippedB);
        await BDTestLib.startEvent(ownerAccount, equipmentTestEvent);
        await BDTestLib.runEventToCompletion(ownerAccount + 1, ownerAccount + 2, equipmentTestEvent);
    });

    it("Should allow combat to succeed with one warrior equipped with a Levelled Up Mace vs an Un-Armed Opponent", async () => {
        var ownerAccount = 24;
        var equipmentTestEvent = await BDTestLib.createEvent(ownerAccount, 2, 4, 0, 5, 10, 10);
        var warriorEquippedA = await BDTestLib.createWarrior(ownerAccount, "Mace Test A", 0, 0, 0, 4, 0, 0, 2, 0);
        var warriorEquippedB = await BDTestLib.createWarrior(ownerAccount, "Mace Test B", 0, 0, 0, 0, 0, 0, 0, 0);
        await BDTestLib.warriorJoinEvent(ownerAccount, equipmentTestEvent, warriorEquippedA);
        await BDTestLib.warriorJoinEvent(ownerAccount, equipmentTestEvent, warriorEquippedB);
        await BDTestLib.startEvent(ownerAccount, equipmentTestEvent);
        await BDTestLib.runEventToCompletion(ownerAccount + 1, ownerAccount + 2, equipmentTestEvent);
    });

    it("Should allow combat to succeed with one warrior equipped with a Levelled Up Hammer vs an Un-Armed Opponent", async () => {
        var ownerAccount = 25;
        var equipmentTestEvent = await BDTestLib.createEvent(ownerAccount, 2, 4, 0, 5, 10, 10);
        var warriorEquippedA = await BDTestLib.createWarrior(ownerAccount, "Hammer Test A", 0, 0, 0, 5, 0, 0, 2, 0);
        var warriorEquippedB = await BDTestLib.createWarrior(ownerAccount, "Hammer Test B", 0, 0, 0, 0, 0, 0, 0, 0);
        await BDTestLib.warriorJoinEvent(ownerAccount, equipmentTestEvent, warriorEquippedA);
        await BDTestLib.warriorJoinEvent(ownerAccount, equipmentTestEvent, warriorEquippedB);
        await BDTestLib.startEvent(ownerAccount, equipmentTestEvent);
        await BDTestLib.runEventToCompletion(ownerAccount + 1, ownerAccount + 2, equipmentTestEvent);
    });

    it("Should allow combat to succeed with one warrior equipped with a Levelled Up Flail vs an Un-Armed Opponent", async () => {
        var ownerAccount = 26;
        var equipmentTestEvent = await BDTestLib.createEvent(ownerAccount, 2, 4, 0, 5, 10, 10);
        var warriorEquippedA = await BDTestLib.createWarrior(ownerAccount, "Flail Test A", 0, 0, 0, 6, 0, 0, 2, 0);
        var warriorEquippedB = await BDTestLib.createWarrior(ownerAccount, "Flail Test B", 0, 0, 0, 0, 0, 0, 0, 0);
        await BDTestLib.warriorJoinEvent(ownerAccount, equipmentTestEvent, warriorEquippedA);
        await BDTestLib.warriorJoinEvent(ownerAccount, equipmentTestEvent, warriorEquippedB);
        await BDTestLib.startEvent(ownerAccount, equipmentTestEvent);
        await BDTestLib.runEventToCompletion(ownerAccount + 1, ownerAccount + 2, equipmentTestEvent);
    });

    it("Should allow combat to succeed with one warrior equipped with a Levelled Up Trident vs an Un-Armed Opponent", async () => {
        var ownerAccount = 27;
        var equipmentTestEvent = await BDTestLib.createEvent(ownerAccount, 2, 4, 0, 5, 10, 10);
        var warriorEquippedA = await BDTestLib.createWarrior(ownerAccount, "Trident Test A", 0, 0, 0, 7, 0, 0, 2, 0);
        var warriorEquippedB = await BDTestLib.createWarrior(ownerAccount, "Trident Test B", 0, 0, 0, 0, 0, 0, 0, 0);
        await BDTestLib.warriorJoinEvent(ownerAccount, equipmentTestEvent, warriorEquippedA);
        await BDTestLib.warriorJoinEvent(ownerAccount, equipmentTestEvent, warriorEquippedB);
        await BDTestLib.startEvent(ownerAccount, equipmentTestEvent);
        await BDTestLib.runEventToCompletion(ownerAccount + 1, ownerAccount + 2, equipmentTestEvent);
    });

    it("Should allow combat to succeed with one warrior equipped with a Levelled Up Halberd vs an Un-Armed Opponent", async () => {
        var ownerAccount = 28;
        var equipmentTestEvent = await BDTestLib.createEvent(ownerAccount, 2, 4, 0, 5, 10, 10);
        var warriorEquippedA = await BDTestLib.createWarrior(ownerAccount, "Halberd Test A", 0, 0, 0, 8, 0, 0, 2, 0);
        var warriorEquippedB = await BDTestLib.createWarrior(ownerAccount, "Halberd Test B", 0, 0, 0, 0, 0, 0, 0, 0);
        await BDTestLib.warriorJoinEvent(ownerAccount, equipmentTestEvent, warriorEquippedA);
        await BDTestLib.warriorJoinEvent(ownerAccount, equipmentTestEvent, warriorEquippedB);
        await BDTestLib.startEvent(ownerAccount, equipmentTestEvent);
        await BDTestLib.runEventToCompletion(ownerAccount + 1, ownerAccount + 2, equipmentTestEvent);
    });

    it("Should allow combat to succeed with one warrior equipped with a Levelled Up Spear vs an Un-Armed Opponent", async () => {
        var ownerAccount = 29;
        var equipmentTestEvent = await BDTestLib.createEvent(ownerAccount, 2, 4, 0, 5, 10, 10);
        var warriorEquippedA = await BDTestLib.createWarrior(ownerAccount, "Spear Test A", 0, 0, 0, 9, 0, 0, 2, 0);
        var warriorEquippedB = await BDTestLib.createWarrior(ownerAccount, "Spear Test B", 0, 0, 0, 0, 0, 0, 0, 0);
        await BDTestLib.warriorJoinEvent(ownerAccount, equipmentTestEvent, warriorEquippedA);
        await BDTestLib.warriorJoinEvent(ownerAccount, equipmentTestEvent, warriorEquippedB);
        await BDTestLib.startEvent(ownerAccount, equipmentTestEvent);
        await BDTestLib.runEventToCompletion(ownerAccount + 1, ownerAccount + 2, equipmentTestEvent);
    });
    */

});
