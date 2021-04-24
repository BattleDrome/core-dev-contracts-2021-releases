// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.1;

import "./WarriorCore.sol";
import "./EventCore.sol";
import "./WagerCore.sol";
import "./SponsorCore.sol";
import "./Utils.sol";

/// @title Core Smart Contract for the BattleDrome Platform. Provides central version control for other components such as WarriorCore and EventCore.
/// @author Paul Mumby
/// @notice For Administrative Interaction Only
/// @dev Currently fairly light-weight, for administrative control/deployment of new contracts in the future. (primarily a placeholder for now)
contract BattleDromeCore is owned,simpleTransferrable {
    
    WarriorCore public warriorCore;
    EventCore public eventCore;
    WagerCore public wagerCore;
    SponsorCore public sponsorCore;
      
    /// @notice Sets up linkages between child core contracts appropriately
    /// @dev Note this is primarily a placeholder for the time being
    /// @param _warriorCore Address for the new WarriorCore Contract
    /// @param _eventCore Address for the new EventCore Contract
    /// @param _wagerCore Address for the new WagerCore Contract
    /// @param _sponsorCore Address for the new SponsorCore Contract
    function setAllChildCores(address _warriorCore, address _eventCore, address _wagerCore, address _sponsorCore) public onlyOwner {
        warriorCore = WarriorCore(_warriorCore);
        eventCore = EventCore(_eventCore);
        wagerCore = WagerCore(_wagerCore);
        sponsorCore = SponsorCore(_sponsorCore);
    }

    /// @notice Sets up linkage for WarriorCore only
    /// @dev Note this is primarily a placeholder for the time being
    /// @param core Address for the new WarriorCore Contract
    function setWarriorCore(address core) public onlyOwner {
        warriorCore = WarriorCore(core);
    }

    /// @notice Sets up linkage for EventCore only
    /// @dev Note this is primarily a placeholder for the time being
    /// @param core Address for the new WarriorCore Contract
    function setEventCore(address core) public onlyOwner {
        eventCore = EventCore(core);
    }

    /// @notice Sets up linkage for WagerCore only
    /// @dev Note this is primarily a placeholder for the time being
    /// @param core Address for the new WagerCore Contract
    function setWagerCore(address core) public onlyOwner {
        wagerCore = WagerCore(core);
    }
    
    /// @notice Sets up linkage for SponsorCore only
    /// @dev Note this is primarily a placeholder for the time being
    /// @param core Address for the new SponsorCore Contract
    function setSponsorCore(address core) public onlyOwner {
        sponsorCore = SponsorCore(core);
    }
     
}