var WarriorCore = artifacts.require("WarriorCore");
var LibWarrior = artifacts.require("LibWarrior");

module.exports = function(deployer) {
    deployer.deploy(LibWarrior);
    deployer.link(LibWarrior,WarriorCore);
    deployer.deploy(WarriorCore);
};
