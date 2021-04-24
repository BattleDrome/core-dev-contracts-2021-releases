// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.1;

import "./Utils.sol";
import "./EventCore.sol";

contract SponsorCore is owned, simpleTransferrable, controlled, mortal {
    //////////////////////////////////////////////////////////////////////////////////////////
    // Config
    //////////////////////////////////////////////////////////////////////////////////////////

    uint constant MIN_SPONSOR_AMOUNT = 1000000 gwei;
    uint constant WINNING_SPONSOR_COUNT = 3;
    uint constant MAX_CONTENT_LENGTH = 512;

    //////////////////////////////////////////////////////////////////////////////////////////
    // Data Structures
    //////////////////////////////////////////////////////////////////////////////////////////
    
    enum AdType {
        Text,
        Image
    }

    struct Ad {
        address payable owner;
        AdType adtype;
        string content;
        string url;
    }

    struct AccountData {
        uint[] ads;
    }

    struct SponsorBid {
        address payable owner;
        uint amount;
        uint ad;
        bool won;
    }

    struct EventData {
        SponsorBid[] sponsors;
        mapping(address=>uint) ownerBids;
        mapping(address=>bool) ownerPresent;
        uint[] winningSponsors;
        bool winnersCalculated;
        bool paid;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // State
    //////////////////////////////////////////////////////////////////////////////////////////

    mapping(uint=>EventData) eventDB;
    Ad[] ads;
    mapping(address=>AccountData) accountAds;
    EventCore public eventCore;

    //////////////////////////////////////////////////////////////////////////////////////////
    // Modifiers
    //////////////////////////////////////////////////////////////////////////////////////////

    modifier onlyAdOwner(uint adID) {
        require(msg.sender == ads[adID].owner,"!OWNER");
        _;
    }

    modifier onlyValidEvents(uint eventID) {
        require(eventCore.getEventCount()>eventID,"!VALIDEVENT");
        _;
    }

    modifier onlyNewEvents(uint eventID) {
        require(eventCore.getEventCount()>eventID,"!VALIDEVENT");
        require(eventCore.getState(eventID)==EventCore.EventState.New,"!EVENTSTATE");
        _;
    }

    modifier onlyEventCore() {
        require(msg.sender==address(eventCore),"!TRUSTED");
        _;
    }

    modifier filterLongContent(string memory content) {
        require(bytes(content).length<=MAX_CONTENT_LENGTH,"!CONTENT_TOO_LONG");
        _;
    }

    modifier onlyValidAds(uint adID) {
        require(ads.length>adID,"!INVALID_AD");
        _;
    }

    modifier onlyCalculatedEvents(uint eventID) {
        require(winnersCalculated(eventID),"!CALCULATED");
        _;
    }

    modifier onlyValidBids(uint eventID, uint bidID) {
        require(getSponsorBidCount(eventID)>bidID,"!INVALID_BID");
        _;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Events
    //////////////////////////////////////////////////////////////////////////////////////////
    
    event NewAd(
        address indexed owner,
        uint indexed id,
        uint32 timeStamp
        );

    event UpdateAd(
        address indexed owner,
        uint indexed id,
        uint32 timeStamp
        );

    event NewBid(
        address indexed owner,
        uint indexed eventID,
        uint bidID,
        uint indexed adID,
        uint amount,
        uint32 timeStamp
        );

    event UpdateBid(
        address indexed owner,
        uint indexed eventID,
        uint bidID,
        uint indexed adID,
        uint amount,
        uint32 timeStamp
        );

    event WinnersCalculated(
        uint indexed eventID,
        uint count,
        uint32 timeStamp
        );
    
    event PaymentTriggered(
        uint indexed eventID,
        uint32 timeStamp
        );

    //////////////////////////////////////////////////////////////////////////////////////////
    // Constructors
    //////////////////////////////////////////////////////////////////////////////////////////
    function newAd(AdType adtype, string memory content, string memory url) public filterLongContent(content) returns(uint) {

        //Create the new Ad:
        Ad memory theNewAd = Ad(payable(msg.sender), adtype, content, url);

        //Add it to the main array, and get it's ID:
        ads.push(theNewAd);
        uint newAdID = ads.length-1;

        //Add it to the owner's dataset:
        accountAds[msg.sender].ads.push(newAdID);

        //Emit the creation event:
        emit NewAd(msg.sender,newAdID,uint32(block.timestamp));

        //Return the created ID:
        return newAdID;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Getters
    //////////////////////////////////////////////////////////////////////////////////////////

    function getAd(uint adID) internal view onlyValidAds(adID) returns(Ad memory) {
        return ads[adID];
    }

    function getAdCount() public view returns(uint) {
        return ads.length;
    }

    function getOwnerAdCount(address owner) public view returns (uint) {
        return accountAds[owner].ads.length;
    }

    function getOwnerAdIDByIndex(address owner, uint index) public view returns (uint) {
        require(accountAds[owner].ads.length>index,"!INVALID_IDX");
        return accountAds[owner].ads[index];
    }

    function getOwner(uint adID) public view onlyValidAds(adID) returns (address payable) {
        return ads[adID].owner;
    }

    function getContent(uint adID) public view onlyValidAds(adID) returns (string memory) {
        return ads[adID].content;
    }

    function getURL(uint adID) public view onlyValidAds(adID) returns (string memory) {
        return ads[adID].url;
    }

    function getType(uint adID) public view onlyValidAds(adID) returns (AdType) {
        return ads[adID].adtype;
    }

    function getSponsorBid(uint eventID, uint sponsorID) internal view onlyValidBids(eventID, sponsorID) returns(SponsorBid memory) {
        return eventDB[eventID].sponsors[sponsorID];
    }

    function getSponsorBidOwner(uint eventID, uint sponsorID) public view returns(address payable) {
        return getSponsorBid(eventID,sponsorID).owner;
    }

    function getSponsorBidAmount(uint eventID, uint sponsorID) public view returns(uint) {
        return getSponsorBid(eventID,sponsorID).amount;
    }
    
    function getSponsorBidAd(uint eventID, uint sponsorID) public view returns(uint) {
        return getSponsorBid(eventID,sponsorID).ad;
    }
    
    function getSponsorBidWon(uint eventID, uint sponsorID) public view returns(bool) {
        return getSponsorBid(eventID,sponsorID).won;
    }

    function getSponsorID(uint eventID) public view returns(uint) {
        require(ownerPresent(eventID,msg.sender),"MISSING_OWNER");
        return eventDB[eventID].ownerBids[msg.sender];
    }
    
    function getSponsorIDByOwner(uint eventID, address owner) public view returns(uint) {
        require(ownerPresent(eventID,owner),"MISSING_OWNER_LOOKUP");
        return eventDB[eventID].ownerBids[owner];
    }

    function ownerPresent(uint eventID, address owner) public view returns(bool) {
        return eventDB[eventID].ownerPresent[owner];
    }

    function getSponsorBidCount(uint eventID) public view returns(uint) {
        return eventDB[eventID].sponsors.length;
    }

    function winnersCalculated(uint eventID) public view returns(bool) {
        return eventDB[eventID].winnersCalculated;
    }
    
    function paid(uint eventID) public view returns(bool) {
        return eventDB[eventID].paid;
    }

    function getWinnerCount(uint eventID) public view onlyValidEvents(eventID) onlyCalculatedEvents(eventID) returns(uint) {
        return eventDB[eventID].winningSponsors.length;
    }

    function getWinningBid(uint eventID, uint index) internal view onlyValidEvents(eventID) onlyCalculatedEvents(eventID) returns(SponsorBid memory) {
        require(eventDB[eventID].winningSponsors.length > index,"!INVALID_WINNER_IDX");
        return eventDB[eventID].sponsors[eventDB[eventID].winningSponsors[index]];
    }

    function getWinningOwner(uint eventID, uint index) public view returns(address payable) {
        return getWinningBid(eventID,index).owner;
    }

    function getWinningAd(uint eventID, uint index) public view returns(uint) {
        return getWinningBid(eventID,index).ad;        
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Setters
    //////////////////////////////////////////////////////////////////////////////////////////
    
    function setEventCore(address core) public onlyOwner {
        eventCore = EventCore(core);
    }

    function setContent(uint adID, string memory content) public onlyValidAds(adID) onlyAdOwner(adID) filterLongContent(content) {
        ads[adID].content = content;
        emit UpdateAd(ads[adID].owner,adID,uint32(block.timestamp));
    }

    function setURL(uint adID, string memory url) public onlyValidAds(adID) onlyAdOwner(adID) {
        ads[adID].url = url;
        emit UpdateAd(ads[adID].owner,adID,uint32(block.timestamp));
    }

    function setType(uint adID, AdType adtype) public onlyValidAds(adID) onlyAdOwner(adID) {
        ads[adID].adtype = adtype;
        emit UpdateAd(ads[adID].owner,adID,uint32(block.timestamp));
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Actions/Activities/Effects
    //////////////////////////////////////////////////////////////////////////////////////////

    function bid(uint eventID, uint ad) public payable onlyAdOwner(ad) onlyNewEvents(eventID) returns (uint) {
        require(msg.value>MIN_SPONSOR_AMOUNT,"<MINAMOUNT");
        if (ownerPresent(eventID, msg.sender)) {
            //Owner has already bid, only one bid per owner
            uint existingBidID = getSponsorIDByOwner(eventID,msg.sender);
            eventDB[eventID].sponsors[existingBidID].amount += msg.value;
            emit UpdateBid(msg.sender, eventID, existingBidID, ad, msg.value, uint32(block.timestamp));
            return existingBidID;          
        } else {
            SponsorBid memory newBid = SponsorBid(payable(msg.sender), msg.value, ad, false);
            eventDB[eventID].sponsors.push(newBid);
            uint newSponsorID = eventDB[eventID].sponsors.length-1;
            eventDB[eventID].ownerPresent[msg.sender] = true;
            eventDB[eventID].ownerBids[msg.sender] = newSponsorID;
            emit NewBid(msg.sender, eventID, newSponsorID, ad, msg.value, uint32(block.timestamp));
            return newSponsorID;
        }
    }

    //Winner Calculation Algorithm. 
    //Figures out who the top bidders are of the bidder pool for a given event.
    //Always called only from the EventCore upon event start (if sponsorship is enabled)
    function calculateWinners(uint eventID) public onlyEventCore() {
        //Check if there are even any bids, if not, ignore the whole thing...
        if(getSponsorBidCount(eventID)>0){
            //Set aside memory array to hold top bid IDs
            int[WINNING_SPONSOR_COUNT] memory topBids;

            //Initialize with -1 to flag empty bids
            for(uint i=0;i<WINNING_SPONSOR_COUNT;i++){
                topBids[i] = -1;
            }

            //Iterate all Sponsorship Bids:
            for(uint s=0;s<getSponsorBidCount(eventID);s++){
                //Then iterate all current winning bids in the memory array:
                for(uint b=0;b<WINNING_SPONSOR_COUNT;b++){
                    //If the current top bid slot is empty, or we found one that's higher than the current top bid slot
                    if( topBids[b]==-1 || ( getSponsorBid(eventID,s).amount > getSponsorBid(eventID,uint(topBids[b])).amount ) ){
                        //Then shift everything down one
                        //This pushes low bids to the end of the array always
                        //Meaning the low bids array will always contain the top bids in descending order of value
                        for(uint x=WINNING_SPONSOR_COUNT-1;x>b;x--) topBids[x] = topBids[x-1];
                        //Since we just shifted everything down one, we can now replace the current bid with the newly found high-bid
                        topBids[b]=int(s);
                        //And break, since we know the remainder of the entries in the array are already sorted and lower than the current bid
                        break;
                    }
                }
            }

            //Now copy/cast over the memory array into storage to persist it.
            for(uint m=0;m<WINNING_SPONSOR_COUNT;m++){
                if(topBids[m]!=-1) eventDB[eventID].winningSponsors.push(uint(topBids[m]));
            }

            //And flag each as winner:
            for(uint w=0;w<eventDB[eventID].winningSponsors.length;w++){
                eventDB[eventID].sponsors[eventDB[eventID].winningSponsors[w]].won = true;
            }

            //Now flag the process as done for this event:
            eventDB[eventID].winnersCalculated = true;

            //And emit our event:
            emit WinnersCalculated(eventID,getWinnerCount(eventID),uint32(block.timestamp));
        }
    }

    //Sponsorship Payout Algorithm. 
    //Returns money to losing bids, and pays everyone elses money to the event owner
    //Always called only from the EventCore upon event completion (if sponsorship is enabled)
    function paySponsorship(uint eventID) public onlyEventCore() {
        
        //Iterate all Sponsorship Bids:
        for(uint s=0;s<getSponsorBidCount(eventID);s++){
            uint bidAmount = getSponsorBidAmount(eventID,s);
            //Check if it was a winning bid:
            if(getSponsorBidWon(eventID,s)){
                //If so, then pay the event owner:
                eventCore.getOwner(eventID).transfer(bidAmount);
            }else{
                //If not, then pay them back:
                getSponsorBidOwner(eventID,s).transfer(bidAmount);
            }
        }
        
        //Mark the process as complete:
        eventDB[eventID].paid = true;

        //And Emit our Event:
        emit PaymentTriggered(eventID,uint32(block.timestamp));
    }    
}

