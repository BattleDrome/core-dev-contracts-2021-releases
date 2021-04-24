let BN = require('bn.js');

var rng_test_lib = {
    instance: null,
    repeatCount: null,
    maxDuplicateRatio: null,
    unboundedFunctions: {},
    boundedFunctions: {},

    init: function (repeatCount, maxDuplicateRatio, unboundedFuncArray, boundedFuncArray) {
        this.repeatCount = repeatCount
        this.maxDuplicateRatio = maxDuplicateRatio
        this.unboundedFunctions = unboundedFuncArray
        this.boundedFunctions = boundedFuncArray
    },

    countDupes: function (searchArray) {
        var counts = {};
        var totalCount = 0;
        searchArray.forEach(function (x) { counts[x] = (counts[x] || 0) + 1; });
        Object.keys(counts).forEach(function (key, index) {
            totalCount += (counts[key] - 1);
        });
        return totalCount
    },

    callRPC: function (rpcCall) {
        return new Promise((resolve, reject) => {
            web3.currentProvider.send(rpcCall, (err, res) => (err ? reject(err) : resolve(res)))
        })
    },

    mine: async function () {
        await this.callRPC({ jsonrpc: "2.0", method: "evm_mine", params: [], id: 0 })
    },

    pause_mining: async function () {
        await this.callRPC({ jsonrpc: "2.0", method: "miner_stop", params: [], id: 0 })
    },

    resume_mining: async function () {
        await this.callRPC({ jsonrpc: "2.0", method: "miner_start", params: [1], id: 0 })
        await this.mine()
    },

    call_rng: function (expectedBits, rangeMin, rangeMax) {
        if (rangeMin.isZero() && rangeMax.isZero()) {
            let rngFunc = this.unboundedFunctions[expectedBits]
            return rngFunc()
        } else {
            let rngFunc = this.boundedFunctions[expectedBits]
            return rngFunc(rangeMin, rangeMax)
        }
    },

    //TODO: Batching isn't actually working, need to look into that. It works in the code, but in ganache it's actually still one per block.
    executeRNGBatch: async function (expectedBits, rangeMin, rangeMax, batchSize) {
        let ranged = !(rangeMin.isZero() && rangeMax.isZero())
        await this.pause_mining()
        var resultSet = [];
        for (var i = 0; i < batchSize; i++) {
            resultSet.push(this.call_rng(expectedBits, rangeMin, rangeMax))
        }
        await this.resume_mining()
        let resolvedResults = await Promise.all(resultSet)
        return resolvedResults.map(txResult => {
            var resultOutput = {
                eventFound: false,
                bits: 0,
                randomVal: 0
            }
            for (var i = 0; i < txResult.logs.length; i++) {
                let log = txResult.logs[i];
                if (log.event == "RandomValueGenerated" && !ranged) {
                    resultOutput.eventFound = true;
                    resultOutput.bits = log.args.bits;
                    resultOutput.randomVal = log.args.value;
                }
                if (log.event == "RandomRangedValueGenerated" && ranged) {
                    resultOutput.eventFound = true;
                    resultOutput.bits = log.args.bits;
                    resultOutput.randomVal = log.args.value;
                }
            }
            return resultOutput
        })
    },

    testRNGResult: function (result, expectedBits, rangeMin, rangeMax) {
        let minVal = (new BN("0",10))
        let maxVal = (new BN("2", 10)).pow(new BN(expectedBits, 10)).sub(new BN("1", 10))
        assert.isTrue(result.eventFound, "The Expected RNG Event Wasn't Emitted!")
        assert.equal(result.bits, expectedBits, "The bit count of the generated value was incorrect!")
        assert.isTrue(result.randomVal.gte(minVal), "The Generated Value (" + result.randomVal.toString() + ") Was Below the Absolute Minimum for expected bit count (" + minVal.toString() + ")!");
        assert.isTrue(result.randomVal.lte(maxVal), "The Generated Value (" + result.randomVal.toString() + ") Was Above the Absolute Maximum for expected bit count (" + maxVal.toString() + ")!");
        if(rangeMax.gt(minVal)){
            //In this case we are testing a bounded random number, so also check if inside those bounds
            assert.isTrue(result.randomVal.gte(rangeMin), "The Generated Value (" + result.randomVal.toString() + ") Was Below the Specified Range Minimum (" + rangeMin.toString() + ")!");
            assert.isTrue(result.randomVal.lte(rangeMax), "The Generated Value (" + result.randomVal.toString() + ") Was Above the Specified Range Maximum (" + rangeMax.toString() + ")!");
        }
    },

    testRNG: async function (expectedBits, ranged, batchSize = 1) {
        //TODO figure out how to specify "Batch size", max number of calls in a single tx.
        let maxVal = (new BN("2", 10)).pow(new BN(expectedBits, 10)).sub(new BN("1", 10))
        let epochCount = this.repeatCount
        if (batchSize > 0) epochCount = Math.ceil(this.repeatCount / batchSize)
        var allResultsArray = []
        for (var epoch = 0; epoch < epochCount; epoch++) {
            rangeMin = new BN("0", 10)
            rangeMax = new BN("0", 10)
            //TODO: Note when troubleshooting RNG error. 
            //      The line below setting range manually to maxVal, throws opcode exception 100% of the time.
            //      While the subsequent line (subtract one more) does not... Related somehow to bug?
            //rangeMax = maxVal
            //rangeMax = maxVal.sub(new BN("1", 10))
            if (ranged) {
                let precision = 10000
                let precisionBN = new BN(precision)
                let minMulBN = new BN(Math.random()*precision)
                let maxMulBN = new BN(Math.random()*precision)
                rangeMin = maxVal.mul(minMulBN).div(precisionBN)
                rangeMax = rangeMin.add(maxVal.sub(rangeMin).mul(maxMulBN).div(precisionBN))
            }
            let resultArray = await this.executeRNGBatch(expectedBits, rangeMin, rangeMax, batchSize)
            resultArray.forEach(result => {
                this.testRNGResult(result, expectedBits, rangeMin, rangeMax)
            })
            allResultsArray = allResultsArray.concat(resultArray)
        }
        let allResultValues = allResultsArray.map(element => element.randomVal)
        let dupeCount = this.countDupes(allResultValues)
        var dupeQuota = Math.ceil(this.repeatCount / 100)
        if (expectedBits <= 32) {
            let randomSpaceCoverage = this.repeatCount / maxVal.toNumber()
            dupeQuota = Math.ceil((this.repeatCount * (1 - this.maxDuplicateRatio)) * randomSpaceCoverage)
        }
        //console.log("DupeCount: " + dupeCount + " DupeQuota: " + dupeQuota)
        //TODO: Figure out better way to test actual randomness of RNG, possibly implement some kind of Birthday function...
        //assert.isAtMost(dupeCount, dupeQuota, "The result set exceeded the max duplicate quota! Insufficient Randomness!")
    }
}

module.exports = rng_test_lib
