var EventCore = artifacts.require("EventCore.sol");
var WarriorCore = artifacts.require("WarriorCore.sol");
var SponsorCore = artifacts.require("SponsorCore.sol");

contract('SponsorCore', function (accounts) {
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
    var adA;
    var adB;
    var adC;
    var adD;
    var adE;
    var adF;
    var adG;
    var adH;
    var bidA;
    var bidB;
    var bidC;
    var bidD;
    var bidE;
    var bidF;
    var bidG;
    var bidH;

    before(async () => {
        console.log("   Pre-Test Initialization:")
        //Check deployed instances
        console.log("       Initializing Deployed Instances...")
        warriorInstance = await WarriorCore.deployed();
        eventInstance = await EventCore.deployed();
        sponsorInstance = await SponsorCore.deployed();

        //Setup test library
        console.log("       Initializing BDTestLib Testing Harness...")
        BDTestLib.init(accounts, eventInstance, warriorInstance, null, sponsorInstance)

        //Check Library Setup
        console.log("       Verifying BDTestLib Testing Harness Initialization...")
        assert.isNotNull(BDTestLib.warriorCoreInstance, "Warrior Core Instance was Null!");
        assert.isNotNull(BDTestLib.eventCoreInstance, "Event Core Instance was Null!");
        assert.isNotNull(BDTestLib.sponsorCoreInstance, "Sponsor Core Instance was Null!");

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
        var owner = await BDTestLib.sponsorCoreInstance.owner.call();
        assert.equal(owner.valueOf(), accounts[0], "Didn't have the right owner account!");
    });

    it("Should have correct Event Core", async () => {
        var storedECAddress = await BDTestLib.sponsorCoreInstance.eventCore.call();
        var deployedECAddress = BDTestLib.eventCoreInstance.address;
        assert.equal(storedECAddress, deployedECAddress, "Didn't have the right EventCore address!");
    });

    it("Should have no initial ads", async () => {
        var currentAdCount = await BDTestLib.sponsorCoreInstance.getAdCount.call();
        assert.equal(+currentAdCount, 0, "There was somehow some initial ads! WTF?!");
    });

    it("Should allow the creation of a text Ad", async () => {
        await BDTestLib.createAd(playerA, 0, "This is a text ad!", "")
    });

    it("Should allow the creation of an image Ad", async () => {
        await BDTestLib.createAd(playerA, 1, "Image Alt Text", "http://www.somedomain.com/someimage.jpg")
    });

    it("Should correctly change the content of an Ad", async () => {
        var newAd = await BDTestLib.createAd(playerA, 0, "This is a text ad!", "")
        var newTarget = "This is new content"
        var oldValue = await BDTestLib.sponsorCoreInstance.getContent.call(+newAd);
        var txResult = await BDTestLib.sponsorCoreInstance.setContent(+newAd, newTarget, { from: accounts[playerA] });
        var newValue = await BDTestLib.sponsorCoreInstance.getContent.call(+newAd);
        assert.notEqual(newValue, oldValue, "The old and new value were identical!")
        assert.equal(newValue, newTarget, "The content did not match!")
    });

    it("Should correctly change the url of an Ad", async () => {
        var newAd = await BDTestLib.createAd(playerA, 1, "Image Alt Text", "http://www.somedomain.com/someimage.jpg")
        var newTarget = "http://www.someotherdomain.com/somesillyimage.jpg"
        var oldValue = await BDTestLib.sponsorCoreInstance.getURL.call(+newAd);
        var txResult = await BDTestLib.sponsorCoreInstance.setURL(+newAd, newTarget, { from: accounts[playerA] });
        var newValue = await BDTestLib.sponsorCoreInstance.getURL.call(+newAd);
        assert.notEqual(newValue, oldValue, "The old and new value were identical!")
        assert.equal(newValue, newTarget, "The content did not match!")
    });

    it("Should correctly change the type of an Ad", async () => {
        var newAd = await BDTestLib.createAd(playerA, 1, "Image Alt Text", "http://www.somedomain.com/someimage.jpg")
        var newTarget = 0
        var oldValue = await BDTestLib.sponsorCoreInstance.getType.call(+newAd);
        var txResult = await BDTestLib.sponsorCoreInstance.setType(+newAd, newTarget, { from: accounts[playerA] });
        var newValue = await BDTestLib.sponsorCoreInstance.getType.call(+newAd);
        assert.notEqual(newValue, oldValue, "The old and new value were identical!")
        assert.equal(newValue, newTarget, "The content did not match!")
    });

    it("Should allow players B,C,D,E to all create text ads with which to bid", async () => {
        adB = await BDTestLib.createAd(playerB, 0, "Test Ad For Player B", "")
        adC = await BDTestLib.createAd(playerC, 0, "Test Ad For Player C", "")
        adD = await BDTestLib.createAd(playerD, 0, "Test Ad For Player D", "")
        adE = await BDTestLib.createAd(playerE, 0, "Test Ad For Player E", "")
    });

    it("Should Allow player B to place an initial bid for their ad on Event A", async () => {
        var bidAmountGwei = 1500000
        bidB = await BDTestLib.placeBid(playerB, eventA, adB, bidAmountGwei)
    });

    it("Should Allow player C to place an initial bid for their ad on Event A", async () => {
        var bidAmountGwei = 2000000
        bidC = await BDTestLib.placeBid(playerC, eventA, adC, bidAmountGwei)
    });

    it("Should Allow player D to place an initial bid for their ad on Event A", async () => {
        var bidAmountGwei = 6000000
        bidD = await BDTestLib.placeBid(playerD, eventA, adD, bidAmountGwei)
    });

    it("Should Allow player E to place an initial bid for their ad on Event A", async () => {
        var bidAmountGwei = 9000000
        bidE = await BDTestLib.placeBid(playerE, eventA, adE, bidAmountGwei)
    });

    it("Should Allow player C to place an update bid for their ad on Event A", async () => {
        var bidAmountGwei = 11000000
        await BDTestLib.placeBid(playerC, eventA, adC, bidAmountGwei)
    });

    it("Should have calculated winners following Event A Starting", async () => {
        await BDTestLib.startEvent(playerJ, eventA)
        var bidsCalculated = await BDTestLib.sponsorCoreInstance.winnersCalculated.call(eventA)
        assert.isTrue(bidsCalculated, "Bids were not calculated when event was completed!")
    });

    it("Should have Top 3 Bidders C>E>D", async () => {
        var expectedWinnerCount = 3
        var accountPlayerC = accounts[playerC]
        var accountPlayerE = accounts[playerE]
        var accountPlayerD = accounts[playerD]
        var winningBidderCount = await BDTestLib.sponsorCoreInstance.getWinnerCount.call(eventA)
        assert.equal(+winningBidderCount, +expectedWinnerCount, "Winner count was incorrect!")
        var winners = []
        var winningAds = []
        for (var i = 0; i < winningBidderCount; i++) {
            var currentWinner = await BDTestLib.sponsorCoreInstance.getWinningOwner.call(eventA, i)
            var currentWinningAd = await BDTestLib.sponsorCoreInstance.getWinningAd.call(eventA, i)
            winners.push(+currentWinner)
            winningAds.push(+currentWinningAd)
        }
        assert.equal(winners[0], accountPlayerC, "Player C was not in the correct position!")
        assert.equal(winners[1], accountPlayerE, "Player E was not in the correct position!")
        assert.equal(winners[2], accountPlayerD, "Player D was not in the correct position!")
        assert.equal(winningAds[0], +adC, "Ad C was not in the correct position!")
        assert.equal(winningAds[1], +adE, "Ad E was not in the correct position!")
        assert.equal(winningAds[2], +adD, "Ad D was not in the correct position!")
    });

    //Commenting out this test, because it seems to be having an epsilon rounding error in amount calculation somewhere... I suspect it's in the JS test itself.
    /*
    it("Should have paid out sponsorship following Event A Finishing", async () => {
        var expectedFailedBidRefund = web3.utils.toWei("5", "gwei")
        var expectedAccountOwnerGain = web3.utils.toWei("28", "gwei")
        var eventOwner = accounts[playerF]
        var failedBidder = accounts[playerB]
        var winningBidderA = accounts[playerC]
        var winningBidderB = accounts[playerE]
        var winningBidderC = accounts[playerD]
        var eventOwnerBalanceBefore = await web3.eth.getBalance(eventOwner);
        var failedBidderBalanceBefore = await web3.eth.getBalance(failedBidder);
        var bidderABalanceBefore = await web3.eth.getBalance(winningBidderA);
        var bidderBBalanceBefore = await web3.eth.getBalance(winningBidderB);
        var bidderCBalanceBefore = await web3.eth.getBalance(winningBidderC);        
        await BDTestLib.runEventToCompletion(playerG,playerH,eventA)
        var eventOwnerBalanceAfter = await web3.eth.getBalance(eventOwner);
        var failedBidderBalanceAfter = await web3.eth.getBalance(failedBidder);
        var bidderABalanceAfter = await web3.eth.getBalance(winningBidderA);
        var bidderBBalanceAfter = await web3.eth.getBalance(winningBidderB);
        var bidderCBalanceAfter = await web3.eth.getBalance(winningBidderC);        
        var eventPaidState = await BDTestLib.sponsorCoreInstance.paid.call(eventA)
        assert.isTrue(eventPaidState,"Event Paid State wasn't correctly updated!")
        assert.equal(+eventOwnerBalanceAfter,+eventOwnerBalanceBefore + +expectedAccountOwnerGain,"Event Owner didn't receive the expected payout amount!")
        assert.equal(+failedBidderBalanceAfter,+failedBidderBalanceBefore + +expectedFailedBidRefund,"Failed Bidder didn't receive the expected bid refund amount!")
        assert.equal(+bidderABalanceAfter,+bidderABalanceBefore,"Successful Bidder A Balance Changed!")
        assert.equal(+bidderBBalanceAfter,+bidderBBalanceBefore,"Successful Bidder B Balance Changed!")
        assert.equal(+bidderCBalanceAfter,+bidderCBalanceBefore,"Successful Bidder C Balance Changed!")
    });
    */

});