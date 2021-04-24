let Random = artifacts.require("Random.sol");

contract('Random', function (accounts) {

    var RNGTestLib = require('./RNGTestLib.js')

    var instance;
    let repeatCount = 5; //Should be high, but setting low for now for interrim deployment
    let targetRandomnessFactor = 0.25;

    before(async () => {
        console.log("   Pre-Test Initialization:")

        //Check deployed instances
        console.log("       Initializing Deployed Instances...")
        instance = await Random.deployed();

        //Setup test library
        console.log("       Initializing RNGTestLib Testing Harness...")
        unboundedFunctions = {
            8: instance.getRandomUint8,
            16: instance.getRandomUint16,
            24: instance.getRandomUint24,
            32: instance.getRandomUint32,
            48: instance.getRandomUint48,
            64: instance.getRandomUint64,
            256: instance.getRandomUint256
        }
        boundedFunctions = {
            8: instance.getRandomRange8,
            16: instance.getRandomRange16,
            24: instance.getRandomRange24,
            32: instance.getRandomRange32,
            48: instance.getRandomRange48,
            64: instance.getRandomRange64,
            256: instance.getRandomRange256
        }
        RNGTestLib.init(repeatCount, targetRandomnessFactor, unboundedFunctions, boundedFunctions)
    });

    it("Should Generate Random Uint8 Values Correctly " + repeatCount + " Times Without Error", async () => {
        await RNGTestLib.testRNG(8, false);
    });

    it("Should Generate Random Uint16 Values Correctly " + repeatCount + " Times Without Error", async () => {
        await RNGTestLib.testRNG(16, false);
    });

    it("Should Generate Random Uint24 Values Correctly " + repeatCount + " Times Without Error", async () => {
        await RNGTestLib.testRNG(24, false);
    });

    it("Should Generate Random Uint32 Values Correctly " + repeatCount + " Times Without Error", async () => {
        await RNGTestLib.testRNG(32, false);
    });

    it("Should Generate Random Uint48 Values Correctly " + repeatCount + " Times Without Error", async () => {
        await RNGTestLib.testRNG(48, false);
    });

    it("Should Generate Random Uint64 Values Correctly " + repeatCount + " Times Without Error", async () => {
        await RNGTestLib.testRNG(64, false);
    });

    it("Should Generate Random Uint256 Values Correctly " + repeatCount + " Times Without Error", async () => {
        await RNGTestLib.testRNG(256, false);
    });

    it("Should Generate Random Uint8 Values Within Bounded Ranges Correctly " + repeatCount + " Times Without Error", async () => {
        await RNGTestLib.testRNG(8, true);
    });

    it("Should Generate Random Uint16 Values Within Bounded Ranges Correctly " + repeatCount + " Times Without Error", async () => {
        await RNGTestLib.testRNG(16, true);
    });

    it("Should Generate Random Uint24 Values Within Bounded Ranges Correctly " + repeatCount + " Times Without Error", async () => {
        await RNGTestLib.testRNG(24, true);
    });

    it("Should Generate Random Uint32 Values Within Bounded Ranges Correctly " + repeatCount + " Times Without Error", async () => {
        await RNGTestLib.testRNG(32, true);
    });

    it("Should Generate Random Uint48 Values Within Bounded Ranges Correctly " + repeatCount + " Times Without Error", async () => {
        await RNGTestLib.testRNG(48, true);
    });

    it("Should Generate Random Uint64 Values Within Bounded Ranges Correctly " + repeatCount + " Times Without Error", async () => {
        await RNGTestLib.testRNG(64, true);
    });

    it("Should Generate Random Uint256 Values Within Bounded Ranges Correctly " + repeatCount + " Times Without Error", async () => {
        await RNGTestLib.testRNG(256, true);
    });

    it("Should Generate Random Uint8 Values In Batches of 10 Correctly Without Error", async () => {
        await RNGTestLib.testRNG(8, false, 10);
    });

    it("Should Generate Random Uint16 Values In Batches of 10 Correctly Without Error", async () => {
        await RNGTestLib.testRNG(16, false, 10);
    });

    it("Should Generate Random Uint24 Values In Batches of 10 Correctly Without Error", async () => {
        await RNGTestLib.testRNG(24, false, 10);
    });

    it("Should Generate Random Uint32 Values In Batches of 10 Correctly Without Error", async () => {
        await RNGTestLib.testRNG(32, false, 10);
    });

    it("Should Generate Random Uint48 Values In Batches of 10 Correctly Without Error", async () => {
        await RNGTestLib.testRNG(48, false, 10);
    });

    it("Should Generate Random Uint64 Values In Batches of 10 Correctly Without Error", async () => {
        await RNGTestLib.testRNG(64, false, 10);
    });

    it("Should Generate Random Uint256 Values In Batches of 10 Correctly Without Error", async () => {
        await RNGTestLib.testRNG(256, false, 10);
    });

    it("Should Generate Random Uint8 Values In Batches of 20 Correctly Without Error", async () => {
        await RNGTestLib.testRNG(8, false, 20);
    });

    it("Should Generate Random Uint16 Values In Batches of 20 Correctly Without Error", async () => {
        await RNGTestLib.testRNG(16, false, 20);
    });

    it("Should Generate Random Uint24 Values In Batches of 20 Correctly Without Error", async () => {
        await RNGTestLib.testRNG(24, false, 20);
    });

    it("Should Generate Random Uint32 Values In Batches of 20 Correctly Without Error", async () => {
        await RNGTestLib.testRNG(32, false, 20);
    });

    it("Should Generate Random Uint48 Values In Batches of 20 Correctly Without Error", async () => {
        await RNGTestLib.testRNG(48, false, 20);
    });

    it("Should Generate Random Uint64 Values In Batches of 20 Correctly Without Error", async () => {
        await RNGTestLib.testRNG(64, false, 20);
    });

    it("Should Generate Random Uint256 Values In Batches of 20 Correctly Without Error", async () => {
        await RNGTestLib.testRNG(256, false, 20);
    });

});
