var BattleDromeCore = artifacts.require("BattleDromeCore.sol");
var EventCore = artifacts.require("EventCore.sol");
var WarriorCore = artifacts.require("WarriorCore.sol");

contract('BattleDromeCore', function(accounts) {

    var coreInstance;
    var wcInstance;
    var ecInstance;

    it("Should be owned by first account", async () => {
        coreInstance = await BattleDromeCore.deployed();
        var owner = await coreInstance.owner.call();
        assert.equal(owner.valueOf(), accounts[0], "Didn't have the right owner account!");
    });

    it("Should have correct Event Core", async () => {
        var storedECAddress = await coreInstance.eventCore.call();
        ecInstance = await EventCore.deployed();
        var deployedECAddress = ecInstance.address;
        assert.equal(storedECAddress, deployedECAddress, "Didn't have the right EventCore address!");
    });

    it("Should have correct Warrior Core", async () => {
        var storedWCAddress = await coreInstance.warriorCore.call();
        wcInstance = await WarriorCore.deployed();
        var deployedWCAddress = wcInstance.address;
        assert.equal(storedWCAddress, deployedWCAddress, "Didn't have the right WarriorCore address!");
    });

});