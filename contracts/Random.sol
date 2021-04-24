// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.1;

import "./Utils.sol";

contract Random is owned,simpleTransferrable,mortal {

    //////////////////////////////////////////////////////////////////////////////////////////
    // Config
    //////////////////////////////////////////////////////////////////////////////////////////

    /* Maybe for later to add some requires.
    uint8 constant UINT8_MIN = 0;
    uint8 constant UINT8_MAX = ~uint8(0);
    uint16 constant UINT16_MIN = 0;
    uint16 constant UINT16_MAX = ~uint16(0);
    uint24 constant UINT24_MIN = 0;
    uint24 constant UINT24_MAX = ~uint24(0);
    uint32 constant UINT32_MIN = 0;
    uint32 constant UINT32_MAX = ~uint32(0);
    uint48 constant UINT48_MIN = 0;
    uint48 constant UINT48_MAX = ~uint48(0);
    uint64 constant UINT64_MIN = 0;
    uint64 constant UINT64_MAX = ~uint64(0);
    */

    //////////////////////////////////////////////////////////////////////////////////////////
    // State
    //////////////////////////////////////////////////////////////////////////////////////////
    uint lastCachedBlock = 0;
    uint nonce = 1;
    bytes32 buffer;
    uint bytesLeft = 0;

    //////////////////////////////////////////////////////////////////////////////////////////
    // Modifiers
    //////////////////////////////////////////////////////////////////////////////////////////
	
    //Check that the cache has sufficient bytes, and recache when needed...
    modifier cacheCheck(uint byteCount) {
        require(byteCount<=32,"TOO MANY BYTES");
        if(bytesLeft<byteCount || block.number > lastCachedBlock) reCache();
		_;
	}

    //////////////////////////////////////////////////////////////////////////////////////////
    // Events
    //////////////////////////////////////////////////////////////////////////////////////////

    event RandomValueGenerated(
        address indexed caller,
        uint32 indexed timeStamp,
        uint16 indexed bits,
        uint value
    );
    
    event RandomRangedValueGenerated(
        address indexed caller,
        uint32 indexed timeStamp,
        uint16 indexed bits,
        uint min,
        uint max,
        uint value
    );

    event CacheRefreshed(
        address indexed caller,
        uint32 indexed timeStamp
    );

    //////////////////////////////////////////////////////////////////////////////////////////
    // Internal Methods
    //////////////////////////////////////////////////////////////////////////////////////////

    function reCache() internal {
        bytesLeft = 32;
        lastCachedBlock = block.number;
        buffer = fetchRandomBuffer();
        emit CacheRefreshed(msg.sender,uint32(block.timestamp));
    }

    function fetchRandomBuffer() internal returns (bytes32) {
        nonce++;
        return keccak256(abi.encodePacked(nonce,blockhash(block.number-1)));
    }   

    function fetchByte() internal returns (uint8) {
        require(bytesLeft>=1,"NOBYTESLEFT");
        bytesLeft -= 1;
        return uint8(buffer[bytesLeft]);
    } 

    function genRandomUint8() internal cacheCheck(1) returns (uint8) {
        uint8 valA = fetchByte();
        return valA;
    }

    function genRandomUint16() internal cacheCheck(2) returns (uint16) {
        uint16 valA = uint16(fetchByte());
        uint16 valB = uint16(fetchByte()) << 8;
        return valA + valB;
    }
    
    function genRandomUint24() internal cacheCheck(3) returns (uint24) {
        uint24 valA = uint24(fetchByte());
        uint24 valB = uint24(fetchByte()) << 8;
        uint24 valC = uint24(fetchByte()) << 16;
        return valA + valB + valC;
    }

    function genRandomUint32() internal cacheCheck(4) returns (uint32) {
        uint32 valA = uint32(fetchByte());
        uint32 valB = uint32(fetchByte()) << 8;
        uint32 valC = uint32(fetchByte()) << 16;
        uint32 valD = uint32(fetchByte()) << 24;
        return valA + valB + valC + valD;
    }

    function genRandomUint48() internal cacheCheck(5) returns (uint48) {
        uint48 valA = uint48(fetchByte());
        uint48 valB = uint48(fetchByte()) << 8;
        uint48 valC = uint48(fetchByte()) << 16;
        uint48 valD = uint48(fetchByte()) << 24;
        uint48 valE = uint48(fetchByte()) << 32;
        return valA + valB + valC + valD + valE;
    }

    function genRandomUint64() internal cacheCheck(6) returns (uint64) {
        uint64 valA = uint64(fetchByte());
        uint64 valB = uint64(fetchByte()) << 8;
        uint64 valC = uint64(fetchByte()) << 16;
        uint64 valD = uint64(fetchByte()) << 24;
        uint64 valE = uint64(fetchByte()) << 32;
        uint64 valF = uint64(fetchByte()) << 40;
        uint64 valG = uint64(fetchByte()) << 48;
        uint64 valH = uint64(fetchByte()) << 56;
        return valA + valB + valC + valD + valE + valF + valG + valH;
    }

    function genRandomUint256() internal returns (uint256) {
        return uint256(fetchRandomBuffer());
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Public Methods
    //////////////////////////////////////////////////////////////////////////////////////////

    function getRandomUint8() public returns (uint8) {
        uint8 randomValue = genRandomUint8();
        emit RandomValueGenerated(msg.sender,uint32(block.timestamp),8,randomValue);
        return randomValue;
    }
    
    function getRandomUint16() public returns (uint16) {
        uint16 randomValue = genRandomUint16();
        emit RandomValueGenerated(msg.sender,uint32(block.timestamp),16,randomValue);
        return randomValue;
    }
    
    function getRandomUint24() public returns (uint24) {
        uint24 randomValue = genRandomUint24();
        emit RandomValueGenerated(msg.sender,uint32(block.timestamp),24,randomValue);
        return randomValue;
    }
    
    function getRandomUint32() public returns (uint32) {
        uint32 randomValue = genRandomUint32();
        emit RandomValueGenerated(msg.sender,uint32(block.timestamp),32,randomValue);
        return randomValue;
    }
    
    function getRandomUint48() public returns (uint48) {
        uint48 randomValue = genRandomUint48();
        emit RandomValueGenerated(msg.sender,uint32(block.timestamp),48,randomValue);
        return randomValue;
    }

    function getRandomUint64() public returns (uint64) {
        uint64 randomValue = genRandomUint64();
        emit RandomValueGenerated(msg.sender,uint32(block.timestamp),64,randomValue);
        return randomValue;
    }
    
    function getRandomUint256() public returns (uint256) {
        uint256 randomValue = genRandomUint256();
        emit RandomValueGenerated(msg.sender,uint32(block.timestamp),256,randomValue);
        return randomValue;
    }

    function getRandomRange8(uint8 min, uint8 max) public returns (uint8) {
        uint8 randomValue = uint8((genRandomUint8() % ((max+1)-min)) + min);
        emit RandomRangedValueGenerated(msg.sender,uint32(block.timestamp),8,min,max,randomValue);
        return randomValue;
    }

    function getRandomRange16(uint16 min, uint16 max) public returns (uint16) {
        uint16 randomValue = uint16((genRandomUint16() % ((max+1)-min)) + min);
        emit RandomRangedValueGenerated(msg.sender,uint32(block.timestamp),16,min,max,randomValue);
        return randomValue;
    }

    function getRandomRange24(uint24 min, uint24 max) public returns (uint24) {
        uint24 randomValue = uint24((genRandomUint24() % ((max+1)-min)) + min);
        emit RandomRangedValueGenerated(msg.sender,uint32(block.timestamp),24,min,max,randomValue);
        return randomValue;
    }

    function getRandomRange32(uint32 min, uint32 max) public returns (uint32) {
        uint32 randomValue = uint32((genRandomUint32() % ((max+1)-min)) + min);
        emit RandomRangedValueGenerated(msg.sender,uint32(block.timestamp),32,min,max,randomValue);
        return randomValue;
    }

    function getRandomRange48(uint48 min, uint48 max) public returns (uint48) {
        uint48 randomValue = uint48((genRandomUint48() % ((max+1)-min)) + min);
        emit RandomRangedValueGenerated(msg.sender,uint32(block.timestamp),48,min,max,randomValue);
        return randomValue;
    }

    function getRandomRange64(uint64 min, uint64 max) public returns (uint64) {
        uint64 randomValue = uint64((genRandomUint64() % ((max+1)-min)) + min);
        emit RandomRangedValueGenerated(msg.sender,uint32(block.timestamp),64,min,max,randomValue);
        return randomValue;
    }

    function getRandomRange256(uint min, uint max) public returns (uint) {
        uint randomValue = (genRandomUint256() % ((max+1)-min)) + min;
        emit RandomRangedValueGenerated(msg.sender,uint32(block.timestamp),256,min,max,randomValue);
        return randomValue;
    }

}

