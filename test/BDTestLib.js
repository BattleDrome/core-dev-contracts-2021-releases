var bd_test_lib = {

    accounts: null,
    eventCoreInstance: null,
    warriorCoreInstance: null,
    wagerCoreInstance: null,
    sponsorCoreInstance: null,
    logEvents: false,
    pollerTotalProfit: 0,
    pollerTotalCount: 0,

    init: function (accounts, eventInstance, warriorInstance, wagerInstance, sponsorInstance) {
        this.accounts = accounts
        this.eventCoreInstance = eventInstance
        this.warriorCoreInstance = warriorInstance
        this.wagerCoreInstance = wagerInstance
        this.sponsorCoreInstance = sponsorInstance
    },

    callRPC: function (rpcCall) {
        return new Promise((resolve, reject) => {
            web3.currentProvider.send(rpcCall, (err, res) => (err ? reject(err) : resolve(res)))
        })
    },

    mine: async function () {
        await this.callRPC({ jsonrpc: "2.0", method: "evm_mine", params: [], id: 0 })
    },

    getBlockTime: async function () {
        let block = await web3.eth.getBlock(web3.eth.blockNumber)
        return block.timestamp
    },

    getTime: async function () {
        return await this.getBlockTime();
    },

    increaseTime: async function (addSeconds) {
        await this.callRPC({ jsonrpc: "2.0", method: "evm_increaseTime", params: [addSeconds], id: 0 })
    },

    doMine: async function (targetBlock) {
        while (web3.eth.blockNumber < targetBlock) {
            await this.mine();
        }
    },

    waitUntilAfter: async function (targetTime) {
        let safetyFactor = 2
        let currentTime = await this.getBlockTime()
        let delay = targetTime - currentTime
        await this.increaseTime(delay * safetyFactor)
        await this.mine()
    },

    waitSeconds: async function (delaySeconds) {
        await this.increaseTime(delaySeconds * 2);
        await this.mine();
    },

    createEvent: async function (accountIdx, wMin, wMax, lMin, lMax, polls, joinFee) {
        //Should allow the appropriate creation check:
        var canCreate = await this.eventCoreInstance.canCreateEvent.call(5, { from: this.accounts[accountIdx] });
        assert.isTrue(canCreate, "canCreateEvent() returned false for accountIDX:" + accountIdx + " with Params: [" + wMin + "," + wMax + "," + lMin + "," + lMax + "," + polls + "," + joinFee + "]!");
        //Let's now actually create the event
        var eventEmitted = false;
        var eventFee = await this.eventCoreInstance.getNewEventFee.call(5, 10);
        var eventID = null;
        txResult = await this.eventCoreInstance.newEvent(wMin, wMax, lMin, lMax, lMin, lMax, polls, web3.utils.toWei(joinFee.toString(), "gwei"), { from: this.accounts[accountIdx], value: eventFee.valueOf() });
        for (var i = 0; i < txResult.logs.length; i++) {
            var log = txResult.logs[i];
            if (log.event == "EventCreated") {
                eventEmitted = true;
                eventID = log.args.event_id;
            }
        }
        assert.equal(eventEmitted, true, "The EventCreated Event was not detected!");
        //Now let's check if it's resulting values are correct:
        var eWarriorMin = await this.eventCoreInstance.getWarriorMin.call(eventID);
        var eWarriorMax = await this.eventCoreInstance.getWarriorMax.call(eventID);
        var eMinLevel = await this.eventCoreInstance.getMinLevel.call(eventID);
        var eMaxLevel = await this.eventCoreInstance.getMaxLevel.call(eventID);
        var eMinEquipLevel = await this.eventCoreInstance.getMinEquipLevel.call(eventID);
        var eMaxEquipLevel = await this.eventCoreInstance.getMaxEquipLevel.call(eventID);
        var eMaxPolls = await this.eventCoreInstance.getMaxPolls.call(eventID);
        var eJoinFee = await this.eventCoreInstance.getJoinFee.call(eventID);
        assert.equal(eWarriorMin, wMin, "The new event had the wrong minimum warrior count!");
        assert.equal(eWarriorMax, wMax, "The new event had the wrong maximum warrior count!");
        assert.equal(eMinLevel, lMin, "The new event had the wrong minimum level!");
        assert.equal(eMaxLevel, lMax, "The new event had the wrong maximum level!");
        assert.equal(eMinEquipLevel, lMin, "The new event had the wrong minimum equipment level!");
        assert.equal(eMaxEquipLevel, lMax, "The new event had the wrong maximum equipment level!");
        assert.equal(eMaxPolls, polls, "The new event had the wrong maximum poll count!");
        assert.equal(eJoinFee, web3.utils.toWei(joinFee.toString(), "gwei"), "The new event had the wrong Join Fee!");
        //Finally assuming all is good, return the resulting event fee to calling test:
        return eventID;
    },

    createWarrior: async function (accountIdx, name, color, armor, shield, weapon, buyArmor = 0, buyShield = 0, buyWeapon = 0, buyPotions = 0) {
        var warriorFee = await this.warriorCoreInstance.getWarriorCost.call();
        var txResult = await this.warriorCoreInstance.newWarrior(this.accounts[accountIdx], color, armor, shield, weapon, { from: this.accounts[accountIdx], value: warriorFee });
        var eventFound = false;
        var warriorID = null;
        var gasUsed = txResult.receipt.cumulativeGasUsed;
        for (var i = 0; i < txResult.logs.length; i++) {
            var log = txResult.logs[i];
            if (log.event == "WarriorCreated") {
                eventFound = true;
                warriorID = log.args.warrior;
                warriorCount = await this.warriorCoreInstance.getGlobalWarriorCount.call();
            }
        }
        assert.isTrue(eventFound, "The Warrior Created Event was Not Emitted!");
        var equipFee = await this.warriorCoreInstance.getEquipCost(warriorID, buyArmor, buyShield, buyWeapon, buyPotions, 0)
        await this.warriorCoreInstance.setName(warriorID, name, { from: this.accounts[accountIdx] });
        var txResultEquip = await this.warriorCoreInstance.buyEquipment(warriorID, buyArmor, buyShield, buyWeapon, buyPotions, 0, { from: this.accounts[accountIdx], value: equipFee })
        for (var i = 0; i < txResultEquip.logs.length; i++) {
            var log = txResultEquip.logs[i];
            if (log.event == "WarriorAltered") {
                alterEventFound = true;
            }
        }
        assert.isTrue(alterEventFound, "The Warrior Altered Event from purchasing equipment was Not Emitted!");
        var armor = await this.warriorCoreInstance.getArmor.call(warriorID);
        var shield = await this.warriorCoreInstance.getShield.call(warriorID);
        var weapon = await this.warriorCoreInstance.getWeapon.call(warriorID);
        var potions = await this.warriorCoreInstance.getPotions.call(warriorID);
        var intPotions = await this.warriorCoreInstance.getIntPotions.call(warriorID);
        assert.equal(armor.toNumber(), buyArmor, "Warrior did not have the correct purchased armor amount!");
        assert.equal(shield.toNumber(), buyShield, "Warrior did not have the correct purchased shield amount!");
        assert.equal(weapon.toNumber(), buyWeapon, "Warrior did not have the correct purchased weapon amount!");
        assert.equal(potions.toNumber(), buyPotions, "Warrior did not have the correct purchased potions amount!");
        assert.equal(intPotions.toNumber(), 0, "Warrior had non-zero starting int potions!");
        return warriorID;
    },

    warriorJoinEvent: async function (accountIdx, eventID, warriorID) {
        var warriorBalance = await this.warriorCoreInstance.getBalance.call(warriorID);
        var joinFee = await this.eventCoreInstance.getJoinFee.call(eventID);
        var oldParticipantCount = await this.eventCoreInstance.getParticipantCount.call(eventID);
        assert.isAbove(+warriorBalance, +joinFee, "The Warrior ID:" + warriorID + " Can't Afford To Join Event ID:" + eventID + "!");
        await this.warriorCoreInstance.joinEvent(warriorID, eventID, { from: this.accounts[accountIdx] });
        var newParticipantCount = await this.eventCoreInstance.getParticipantCount.call(eventID);
        assert.isAbove(+newParticipantCount, +oldParticipantCount, "Event ID:" + eventID + " Participant Count did not increase as expected for warrior ID:" + warriorID + "!");
    },

    startEvent: async function (accountIdxA, eventID) {
        let maxRetries = 60;
        var retries = 0;
        while (await this.eventCoreInstance.canStart.call(eventID) != true && retries < maxRetries) {
            await this.waitSeconds(30);
            retries++
        }
        var canStart = await this.eventCoreInstance.canStart.call(eventID);
        assert.isTrue(canStart, "The Event canStart() for event ID:" + eventID + " check failed, and maximum of " + maxRetries + " retries were attempted!");
        var txResult = await this.eventCoreInstance.start(eventID, { from: this.accounts[accountIdxA] });
        var gasUsed = txResult.receipt.cumulativeGasUsed;
        var eventFound = false;
        var startedEventID = 0;
        for (var i = 0; i < txResult.logs.length; i++) {
            var log = txResult.logs[i];
            if (log.event == "EventStarted") {
                eventFound = true;
                startedEventID = log.args.event_id;
            }
        }
        assert.isTrue(eventFound.valueOf(), "The Event Started Event was not emitted for event ID:" + eventID + "!");
        assert.equal(startedEventID.toString(), eventID.toString(), "The event that started had the wrong ID!");
        var newState = await this.eventCoreInstance.getState.call(eventID);
        assert.equal(newState.valueOf(), 1, "The Event State of event ID:" + eventID + " did not update to Active as expected!");
        var firstParticipant = await this.eventCoreInstance.getParticipant.call(eventID, 0);
        var secondParticipant = await this.eventCoreInstance.getParticipant.call(eventID, 1);
        var firstState = await this.warriorCoreInstance.getState.call(firstParticipant);
        var secondState = await this.warriorCoreInstance.getState.call(secondParticipant);
        assert.equal(firstState.valueOf(), 5, "The first warrior ID:" + firstParticipant + " didn't enter Battling state as expected due to event ID:" + eventID + " starting!");
        assert.equal(secondState.valueOf(), 5, "The second warrior ID:" + secondParticipant + " didn't enter Battling state as expected due to event ID:" + eventID + " starting!");
    },

    runEventToCompletion: async function (accountIdxA, accountIdxB, eventID) {
        var EventFinished = false;
        var defeatOccurred = false;
        var winnerFound = false;
        var txResult;
        var gasUsed;
        var killedID;
        var killerID;
        var defeatLoot;
        var winnerID;
        var polls = 0;
        var totalGas = 0;
        var pollGasPrice = web3.utils.toWei("5", "gwei");
        var warriorStartingBalance = await this.warriorCoreInstance.getWarriorCost.call();
        var maxPolls = (await this.eventCoreInstance.getMaxPolls.call(eventID)).valueOf();
        var pollerAStartingBalance = web3.utils.fromWei(await web3.eth.getBalance(this.accounts[accountIdxA]), "gwei").valueOf()
        var pollerBStartingBalance = web3.utils.fromWei(await web3.eth.getBalance(this.accounts[accountIdxB]), "gwei").valueOf()
        while (!EventFinished) {
            await this.waitSeconds(30);
            if (polls % 2 == 1) {
                txResult = await this.eventCoreInstance.poll(eventID, { from: this.accounts[accountIdxA], gasPrice: pollGasPrice });
            } else {
                txResult = await this.eventCoreInstance.poll(eventID, { from: this.accounts[accountIdxB], gasPrice: pollGasPrice });
            }
            gasUsed = txResult.receipt.cumulativeGasUsed;
            polls++;
            assert.isBelow(+polls, +maxPolls + 1, "Polls for Event ID:" + eventID + " exceeded the maximum poll count!");
            totalGas += gasUsed;
            for (var i = 0; i < txResult.logs.length; i++) {
                var log = txResult.logs[i];
                if (log.event == "WarriorEngaged") {
                    var A = log.args.warriorA;
                    var B = log.args.warriorB;
                    if (this.logEvents) console.log(A + " and " + B + " have engaged in battle!");
                }
                if (log.event == "WarriorHit") {
                    var defender = log.args.warrior;
                    var attacker = log.args.attacker;
                    var dmg = log.args.damageDealt;
                    if (dmg > 0 && this.logEvents) console.log(attacker + " Hit " + defender + " for " + dmg + " Damage!");
                    if (dmg <= 0 && this.logEvents) console.log(attacker + " Hit " + defender + " but he withstood the blow!");
                }
                if (log.event == "WarriorDodged") {
                    var defender = log.args.warrior;
                    var attacker = log.args.attacker;
                    if (this.logEvents) console.log(defender + " Dodged " + attacker + "'s Attack!");
                }
                if (log.event == "WarriorBlocked") {
                    var defender = log.args.warrior;
                    var attacker = log.args.attacker;
                    var dmg = log.args.damageBlocked;
                    if (this.logEvents) console.log(defender + " Blocked " + damageBlocked + " damage from " + defender + "'s Attack!");
                }
                if (log.event == "WarriorEscaped") {
                    var defender = log.args.warrior;
                    var attacker = log.args.attacker;
                    if (this.logEvents) console.log(defender + " Escaped From Battle With " + attacker + "!");
                }
                if (log.event == "WarriorDrankPotion") {
                    var defender = log.args.warrior;
                    var attacker = log.args.attacker;
                    if (this.logEvents) console.log(defender + " was nearly killed by " + attacker + "'s attack, but drank a potion to stay alive!");
                }
                if (log.event == "WarriorDefeated") {
                    killedID = log.args.warrior;
                    killerID = log.args.attacker;
                    defeatOccurred = true;
                    if (this.logEvents) console.log(killerID + " Defeated " + killedID + "!");
                }
                if (log.event == "EventWinner") {
                    winnerID = log.args.warrior;
                    winnerFound = true;
                    if (this.logEvents) console.log(winnerID + " has been declared the Winner!");
                }
                if (log.event == "EventFinished") {
                    EventFinished = true;
                    if (this.logEvents) console.log("The event has completed!");
                }
            }
        }
        var avgGas = totalGas / polls;
        assert.isTrue(EventFinished.valueOf(), "The event ID:" + eventID + " did not finish!");
        if (defeatOccurred) {
            var killedState = await this.warriorCoreInstance.getState(killedID);
            var killerBalance = await this.warriorCoreInstance.getBalance(killerID);
            var killerXP = await this.warriorCoreInstance.getXP(killerID);
            assert.equal(killedState.valueOf(), 6, "The defeated warrior in event ID:" + eventID + " did not update to Incapacitated State as expected!");
            assert.isAbove(+killerBalance.valueOf(), +warriorStartingBalance.valueOf(), "The killer's balance didn't increase in event ID:" + eventID + "!");
            assert.isAbove(+killerXP.valueOf(), 0, "The killer didn't earn any XP for some reason in event ID:" + eventID + "!");
        }
        assert.isBelow(+avgGas.valueOf(), 6000000, "Too much average gas per poll for event ID:" + eventID + " (>6M or > 50% of block limit)!");
        var pollerAEndingBalance = web3.utils.fromWei(await web3.eth.getBalance(this.accounts[accountIdxA]), "gwei").valueOf()
        var pollerBEndingBalance = web3.utils.fromWei(await web3.eth.getBalance(this.accounts[accountIdxB]), "gwei").valueOf()
        var pollerAProfit = +pollerAEndingBalance - +pollerAStartingBalance
        var pollerBProfit = +pollerBEndingBalance - +pollerBStartingBalance
        assert.isAtLeast(+pollerAProfit, 0, "Poller A Lost Money For Polling Event ID:" + eventID)
        assert.isAtLeast(+pollerBProfit, 0, "Poller B Lost Money For Polling Event ID:" + eventID)
        this.pollerTotalCount += 2
        this.pollerTotalProfit += (pollerAProfit + pollerBProfit)
    },

    placeWager: async function (player, eventID, warriorID, wagerAmount) {
        var caller = this.accounts[player]
        var currentPool = await this.wagerCoreInstance.getEventTotalWagerPool.call(eventID);
        var prevCallerPresent = await this.wagerCoreInstance.ownerPresent.call(eventID, caller);
        var prevWagerAmount = 0;
        var prevCallerWagerID = -1;
        if (prevCallerPresent) {
            prevCallerWagerID = (await this.wagerCoreInstance.getWagerIDByOwner.call(eventID, caller)).toNumber();
            prevWagerAmount = await this.wagerCoreInstance.getWagerAmount.call(eventID, prevCallerWagerID);
        }
        var txResult = await this.wagerCoreInstance.wager(warriorID, eventID, { value: wagerAmount, from: caller });
        var newPool = await this.wagerCoreInstance.getEventTotalWagerPool.call(eventID);
        var callerPresent = await this.wagerCoreInstance.ownerPresent.call(eventID, caller);
        var callerWagerID = (await this.wagerCoreInstance.getWagerIDByOwner.call(eventID, caller)).toNumber();
        var newWagerAmount = await this.wagerCoreInstance.getWagerAmount.call(eventID, callerWagerID);
        var gasUsed = txResult.receipt.cumulativeGasUsed;
        var eventFound = false;
        var newWager = false;
        for (var i = 0; i < txResult.logs.length; i++) {
            var log = txResult.logs[i];
            if (log.event == "NewWager") {
                eventFound = true;
                newWager = true;
                seenWagerOwner = log.args.owner;
                seenWagerAmount = log.args.amount.valueOf();
                seenWagerWarrior = log.args.warriorID.valueOf();
                seenWagerEvent = log.args.eventID.valueOf();
                assert.equal(+seenWagerOwner, caller, "Wager Owner in NewWager Event didn't accurately reflect the account requesting it!");
                assert.equal(+seenWagerAmount, +wagerAmount, "Wager Amount in NewWager Event didn't accurately reflect the wager amount requested!");
                assert.equal(+seenWagerWarrior, +warriorID, "Wager WarriorID in NewWager Event didn't accurately reflect the wager warrior requested!");
                assert.equal(+seenWagerEvent, +eventID, "Wager EventID in NewWager Event didn't accurately reflect the event in which the wager was requested!");
            }
            if (log.event == "AddWager") {
                eventFound = true;
                newWager = false;
                seenWagerOwner = log.args.owner;
                seenWagerAmount = log.args.amount.valueOf();
                seenWagerEvent = log.args.eventID.valueOf();
                assert.equal(+seenWagerOwner, caller, "Wager Owner in AddWager Event didn't accurately reflect the account requesting it!");
                assert.equal(+seenWagerAmount, +wagerAmount, "Wager Amount in AddWager Event didn't accurately reflect the wager amount requested!");
                assert.equal(+seenWagerEvent, +eventID, "Wager EventID in AddWager Event didn't accurately reflect the event in which the wager was requested!");
            }
        }
        assert.isTrue(eventFound, "No Wager Event was detected!");
        assert.isTrue(callerPresent, "Wager Owner is not present in the specified event's Wager list!");
        assert.isAbove(+newPool, +currentPool, "New Total Wager Pool didn't increase!");
        assert.isAbove(+newWagerAmount, +prevWagerAmount, "Wager Amount for this Warrior/Event combo did not increase!")
        if (newWager) {
            assert.isBelow(+gasUsed, 250000, "wager() call for NEW wager used more than 250k Gas!");
        } else {
            assert.isBelow(+gasUsed, 100000, "wager() call for UPDATE wager used more than 100k Gas!");
        }
    },

    createAd: async function (accountIdx, type, content, url) {
        var oldAdCount = await this.sponsorCoreInstance.getAdCount.call();
        var txResult = await this.sponsorCoreInstance.newAd(type, content, url, { from: this.accounts[accountIdx] });
        var eventFound = false;
        var adID = null;
        for (var i = 0; i < txResult.logs.length; i++) {
            var log = txResult.logs[i];
            if (log.event == "NewAd") {
                eventFound = true;
                adID = log.args.id;
                var newAdCount = await this.sponsorCoreInstance.getAdCount.call();
            }
        }
        var adOwner = await this.sponsorCoreInstance.getOwner.call(adID);
        var adType = await this.sponsorCoreInstance.getType.call(adID);
        var adContent = await this.sponsorCoreInstance.getContent.call(adID);
        var adURL = await this.sponsorCoreInstance.getURL.call(adID);
        assert.isTrue(eventFound, "The Ad Creation Event was Not Emitted!");
        assert.isAbove(+newAdCount, +oldAdCount, "The Ad Count did not Increase!")
        assert.equal(adOwner, this.accounts[accountIdx], "The Created Ad did not have the correct owner!")
        assert.equal(+adType, type, "The Created Ad did not have the correct type!")
        assert.equal(adContent, content, "The Created Ad did not have the correct content!")
        assert.equal(adURL, url, "The Created Ad did not have the correct url!")
        return adID;
    },

    placeBid: async function (accountIdx, eventID, adID, amountGwei) {
        var actualBidAmount = web3.utils.toWei(amountGwei.toString(), "gwei")
        var account = this.accounts[accountIdx]
        var oldBidCount = await this.sponsorCoreInstance.getSponsorBidCount.call(eventID)
        var ownerPresent = await this.sponsorCoreInstance.ownerPresent.call(eventID, account)
        var prevBidAmount = 0
        if (ownerPresent) {
            var prevBidID = (await this.sponsorCoreInstance.getSponsorIDByOwner.call(eventID, account)).toNumber()
            var prevBidAmount = await this.sponsorCoreInstance.getSponsorBidAmount.call(eventID, prevBidID);
        }
        var txResult = await this.sponsorCoreInstance.bid(eventID, adID, { from: account, value: actualBidAmount })
        var eventFound = false;
        var bidID;
        for (var i = 0; i < txResult.logs.length; i++) {
            var log = txResult.logs[i];
            if (log.event == "NewBid") {
                eventFound = true;
                bidID = log.args.bidID;
                var newBidCount = await this.sponsorCoreInstance.getSponsorBidCount.call(eventID)
                var bidAmount = await this.sponsorCoreInstance.getSponsorBidAmount.call(eventID, bidID);
                assert.isAbove(+newBidCount, +oldBidCount, "The Bid Count for the event did not Increase in the event of a new bid!")
                assert.equal(+bidAmount, +actualBidAmount, "The bid amount on a new bid was not the expected amount!")
            }
            if (log.event == "UpdateBid") {
                eventFound = true;
                bidID = log.args.bidID;
                assert.equal(+bidID, +prevBidID, "The ID did not match previous bid, in the case of an updated bid.")
                var newBidCount = await this.sponsorCoreInstance.getSponsorBidCount.call(eventID)
                var bidAmount = await this.sponsorCoreInstance.getSponsorBidAmount.call(eventID, bidID);
                assert.equal(+newBidCount, +oldBidCount, "The Bid Count an update changed and it shouldn't have!")
                var expectedBidAmount = (+prevBidAmount) + (+actualBidAmount)
                assert.equal(+bidAmount, +expectedBidAmount, "The bid amount on an updated bid did not increase by the expected amount!")
            }
        }
        assert.isTrue(eventFound, "A Bid Creation or Update Event was Not Emitted!");
        var bidOwner = await this.sponsorCoreInstance.getSponsorBidOwner.call(eventID, bidID);
        var bidAd = await this.sponsorCoreInstance.getSponsorBidAd.call(eventID, bidID);
        var bidWon = await this.sponsorCoreInstance.getSponsorBidWon.call(eventID, bidID);
        assert.equal(bidOwner, account, "The account was not as expected for the bid!")
        assert.equal(+bidAd, +adID, "The Ad used in the bid was not as expected!")
        assert.isFalse(bidWon, "The bid status is marked as Won!")
    }
}

module.exports = bd_test_lib
