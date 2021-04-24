var BattleDromeCore = artifacts.require("BattleDromeCore");
var EventCore = artifacts.require("EventCore");
var WarriorCore = artifacts.require("WarriorCore");
var WagerCore = artifacts.require("WagerCore");
var SponsorCore = artifacts.require("SponsorCore");
var Random = artifacts.require("Random");

module.exports = async function (deployer, networks, accounts) {
    let coreInstance = await BattleDromeCore.deployed()
    let ecInstance = await EventCore.deployed()
    let wcInstance = await WarriorCore.deployed()
    let wagerInstance = await WagerCore.deployed()
    let sponsorInstance = await SponsorCore.deployed()
    let randomInstance = await Random.deployed()
    await ecInstance.changeController(coreInstance.address)
    await wcInstance.changeController(coreInstance.address)
    await wagerInstance.changeController(coreInstance.address)
    await sponsorInstance.changeController(coreInstance.address)
    await coreInstance.setAllChildCores(wcInstance.address, ecInstance.address, wagerInstance.address, sponsorInstance.address)
    await ecInstance.setWarriorCore(wcInstance.address)
    await ecInstance.setWagerCore(wagerInstance.address)
    await ecInstance.setSponsorCore(sponsorInstance.address)
    await ecInstance.setRNG(randomInstance.address)
    await wcInstance.setEventCore(ecInstance.address)
    await wcInstance.setRNG(randomInstance.address)
    await wagerInstance.setEventCore(ecInstance.address)
    await wagerInstance.setWarriorCore(wcInstance.address)
    await sponsorInstance.setEventCore(ecInstance.address)
}

