// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./Address.sol";
import "./SafeMath.sol";

contract Palladium is ERC20, Ownable {
    using Address for address;
    using SafeMath for uint256;
    
    // BOOLS
    
    bool pauseRewards = false;
    
    // ADDRESS
    
    address public unespiedMinter;
    
    // UINTS
    
    uint256 public wormholeConstruction = 450000 * (10**18);
    uint256 public wormholeRebuild = 30000 * (10**18);
    uint256 public secondaryRequirement = 190000 * (10**18);
    uint256 public warCooldown = 604800;
    
    // MAPPING
    
    mapping(address => bool) public approved;
    mapping(address => uint256) public secondaryOwned;
    
    mapping(uint256 => Planets) public planets;
    mapping(uint256 => UnespiedIdentification) public workPass;
    mapping(uint256 => mapping(uint256 => Wormholes)) public factionWormholes;
    mapping(uint256 => mapping(uint256 => PlanetWars)) public warStats;
    
    // STRUCTS
    
    struct UnespiedIdentification {
        uint256 planetWorking;
        uint256 palladiumRate;
        uint256 secondaryRate;
        uint256 planetStartTime;
    }
    
    struct Planets {
        uint256 palladiumRates;
        uint256 secondaryRates;
        uint256 controllingFaction;
    }
    
    struct Wormholes {
        uint256 palladiumContributed;
        uint256 repairContributed;
        bool created;
        bool active;
    }
    
    struct PlanetWars {
        uint256 secondaryContribution;
        uint256 lastTimeSeiged;
        uint256 rewardStartTime;
        uint256 rewardEndTime;
        bool currentlyContested;
    }
    
    constructor() ERC20("Palladium","PLDM") {
        
    }
    
    ////REMOVE BEFORE DEPLOYMENT!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!///////////
    function mint() external onlyOwner {
        _mint(msg.sender, 1000000000000 * (10**18));
    }
    ////REMOVE BEFORE DEPOLOYMENT (ABOVE CODE)!!!!!!!!!!!!!!!!!!!!!!!////////////
    
    function updateAllCosts(uint256 _construction, uint256 _rebuild, uint256 _secondary) external onlyOwner {
        wormholeConstruction = _construction;
        wormholeRebuild = _rebuild;
        secondaryRequirement = _secondary;
    }
    
    function updateConstructionCost(uint256 _newCost) external onlyOwner {
        wormholeConstruction = _newCost;
    }
    
    function updateRebuildCost(uint256 _newCost) external onlyOwner {
        wormholeRebuild = _newCost;
    }
    
    function updateSecondaryRequirement(uint256 _newCost) external onlyOwner {
        secondaryRequirement = _newCost;
    }
    
    function setWarCooldown(uint256 _newCooldown) external onlyOwner {
        warCooldown = _newCooldown;
    }
    
    function setAllPlanetRates(uint256[] calldata _planetID, uint256[] calldata _primary, uint256[] calldata _secondary) external onlyOwner {
        require(_planetID.length == _primary.length && _planetID.length == _secondary.length, "INCORRECT DATA STRUCTURE PROVIDED");
        
        for(uint256 i = 0; i < _planetID.length; i++) {
            planets[_planetID[i]].palladiumRates = _primary[_primary[i]];
            planets[_planetID[i]].secondaryRates = _secondary[_secondary[i]];
        }
        
    }
    
    function setPlanetRates(uint256 _planetID, uint256 _primary, uint256 _secondary) external onlyOwner {
        planets[_planetID].palladiumRates = _primary;
        planets[_planetID].secondaryRates = _secondary;
    }
    
    function viewPlanetRates(uint256 _planetID) external view returns(uint256, uint256) {
        uint256 pRate = planets[_planetID].palladiumRates;
        uint256 sRate = planets[_planetID].secondaryRates;
        return (pRate, sRate);
    }
    
    function buildWormhole(uint256 _planetID, uint256 _factionId, uint256 _amount) external {
        require(factionWormholes[_factionId][_planetID].created == false, "WORMHOLE ALREADY BUILT");
        
        burnPalladium(msg.sender, _amount);
        
        bool cValue = factionWormholes[_factionId][_planetID].palladiumContributed.add(_amount) > wormholeConstruction;
            
        if(cValue == false) {
            factionWormholes[_factionId][_planetID].palladiumContributed = factionWormholes[_factionId][_planetID].palladiumContributed.add(_amount);
        }
            
        if(cValue == true) {
            uint256 wAmount = wormholeConstruction.sub(factionWormholes[_factionId][_planetID].palladiumContributed);
            uint256 rAmount = _amount.sub(wAmount);
                
            factionWormholes[_factionId][_planetID].palladiumContributed = factionWormholes[_factionId][_planetID].palladiumContributed.add(wAmount);
                
            factionWormholes[_factionId][_planetID].repairContributed = factionWormholes[_factionId][_planetID].repairContributed.add(rAmount);
        }
        
        if(factionWormholes[_factionId][_planetID].palladiumContributed == wormholeConstruction) {
            factionWormholes[_factionId][_planetID].created = true;
            factionWormholes[_factionId][_planetID].active = true;
        }
    }
    
    function rebuildWormhole(uint256 _planetID, uint256 _factionId, uint256 _amount) external {
        require(factionWormholes[_factionId][_planetID].created == true, "WORMHOLE NOT YET BUILT");
        require(factionWormholes[_factionId][_planetID].active == false, "WORMHOLE IS NOT DEPLETED");
        
        burnPalladium(msg.sender, _amount);
        
        bool cValue = factionWormholes[_factionId][_planetID].repairContributed.add(_amount) > wormholeRebuild;
        
        if(cValue == false) {
            factionWormholes[_factionId][_planetID].repairContributed = factionWormholes[_factionId][_planetID].repairContributed.add(_amount);
        }
        
        if(cValue == true) {
            factionWormholes[_factionId][_planetID].repairContributed = factionWormholes[_factionId][_planetID].repairContributed.add(_amount);
            factionWormholes[_factionId][_planetID].active = true;
            factionWormholes[_factionId][_planetID].repairContributed = factionWormholes[_factionId][_planetID].repairContributed.sub(wormholeRebuild);
        }
    }
    
    function declareWar(uint256 _planetID, uint256 _factionId) external {
        require(factionWormholes[_factionId][_planetID].active = true, "WORMHOLE IS NOT ACTIVE TO THIS PLANET");
        uint256 wFaction = planets[_planetID].controllingFaction;
        require(block.timestamp >= warStats[_planetID][wFaction].lastTimeSeiged.add(warCooldown), "PLANET IS NOT YET ELIGIBLE FOR A WAR");
        
        if(planets[_planetID].controllingFaction == 0) {
            planets[_planetID].controllingFaction = _factionId;
            warStats[_planetID][_factionId].rewardStartTime = block.timestamp;
        }
        
        if(planets[_planetID].controllingFaction != 0) {
            warStats[_planetID][_factionId].currentlyContested = true;
            warStats[_planetID][planets[_planetID].controllingFaction].currentlyContested = true;
        }
        
    }
    
    function warContribution(uint256 _planetID, uint256 _factionId, uint256 _secondary) external {
        require(warStats[_planetID][_factionId].currentlyContested = true, "WAR IS NOT ACTIVE ON THIS PLANET");
        require(secondaryOwned[msg.sender] >= _secondary, "INSUFFCIENT RESOURCES");
        
        bool cAmount = warStats[_planetID][_factionId].secondaryContribution.add(_secondary) >= secondaryRequirement;
        
        if(cAmount == false) {
            secondaryOwned[msg.sender] = secondaryOwned[msg.sender].sub(_secondary);
            warStats[_planetID][_factionId].secondaryContribution = warStats[_planetID][_factionId].secondaryContribution.add(_secondary);
        }
        
        if(cAmount == true) {
            uint256 sAmount = secondaryRequirement.sub(warStats[_planetID][_factionId].secondaryContribution);
            secondaryOwned[msg.sender] = secondaryOwned[msg.sender].sub(sAmount);
            warStats[_planetID][_factionId].secondaryContribution = warStats[_planetID][_factionId].secondaryContribution.add(sAmount);
        }
        
        if(warStats[_planetID][_factionId].secondaryContribution >= secondaryRequirement) {
            uint256 lFaction = planets[_planetID].controllingFaction;
            
            planets[_planetID].controllingFaction = _factionId;
            warStats[_planetID][_factionId].rewardStartTime = block.timestamp;
            warStats[_planetID][lFaction].rewardEndTime = block.timestamp;
            warStats[_planetID][_factionId].currentlyContested = false;
            warStats[_planetID][lFaction].currentlyContested = false;
            factionWormholes[_planetID][lFaction].active = false;
            warStats[_planetID][_factionId].lastTimeSeiged = block.timestamp;
        }
    }
    
    function transferSecondary(address _recipient, uint256 _amount) external {
        require(balanceOf(msg.sender) >= _amount);
        
        secondaryOwned[msg.sender] = secondaryOwned[msg.sender].sub(_amount);
        secondaryOwned[_recipient] = secondaryOwned[_recipient].add(_amount);
    }
    
    function setUnespiedMinter(address _minter) external onlyOwner {
        unespiedMinter = _minter;
    }
    
    function setApprovedStatus(address _address, bool _trueOrFalse) external onlyOwner {
        approved[_address] = _trueOrFalse;
    }
    
    function suffcientBalance(address _spender, uint256 _amount) external view returns(bool) {
        return balanceOf(_spender) >= _amount;
    }
    
    function burnPalladium(address _burner, uint256 _amount) public {
        require(msg.sender == _burner || msg.sender == address(unespiedMinter) || approved[msg.sender] == true, "NOT PERMISSABLE FROM SELECTED ADDRESS");
        require(balanceOf(_burner) >= _amount, "INSUFFCIENT PALLADIUM BALANCE");
        
        _burn(_burner, _amount);
    }
    
}
