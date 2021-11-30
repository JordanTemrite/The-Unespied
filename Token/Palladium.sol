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
        uint256 previousPlanet;
        uint256 faction;
        uint256 planetStartTime;
        uint256 lastClaimed; 
    }
    
    struct Planets {
        uint256 palladiumRates;
        uint256 secondaryRates;
        uint256 controllingFaction;
        uint256 contestingFaction;
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
    
    function setAllPlanetRates(uint256[] calldata _planetID, uint256[] calldata _primary, uint256[] calldata _secondary, uint256[] calldata _factions) external onlyOwner {
        require(_planetID.length == _primary.length && _planetID.length == _secondary.length && _planetID.length == _factions.length, "INCORRECT DATA STRUCTURE PROVIDED");
        
        for(uint256 i = 0; i < _planetID.length; i++) {
            planets[_planetID[i]].palladiumRates = _primary[i];
            planets[_planetID[i]].secondaryRates = _secondary[i];
            planets[_planetID[i]].controllingFaction = _factions[i];
        }
        
    }
    
    function setPlanetRates(uint256 _planetID, uint256 _primary, uint256 _secondary, uint256 _faction) external onlyOwner {
        planets[_planetID].palladiumRates = _primary;
        planets[_planetID].secondaryRates = _secondary;
        planets[_planetID].controllingFaction = _faction;
    }
    
    function viewPlanetRates(uint256 _planetID) external view returns(uint256, uint256) {
        uint256 pRate = planets[_planetID].palladiumRates;
        uint256 sRate = planets[_planetID].secondaryRates;
        return (pRate, sRate);
    }
    
    function setRewardState() external onlyOwner {
        pauseRewards = !pauseRewards;
    }
    
    function buildWormhole(uint256 _planetID, uint256 _factionId, uint256 _amount) external {
        require(factionWormholes[_planetID][_factionId].created == false, "WORMHOLE ALREADY BUILT");
        require(_planetID != 1 || _planetID != 2 || _planetID != 3 || _planetID != 0, "CANNOT ATTACK HOME PLANETS");
        
        burnPalladium(msg.sender, _amount);
        
        bool cValue = factionWormholes[_planetID][_factionId].palladiumContributed.add(_amount) > wormholeConstruction;
            
        if(cValue == false) {
            factionWormholes[_planetID][_factionId].palladiumContributed = factionWormholes[_planetID][_factionId].palladiumContributed.add(_amount);
        }
            
        if(cValue == true) {
            uint256 wAmount = wormholeConstruction.sub(factionWormholes[_planetID][_factionId].palladiumContributed);
            uint256 rAmount = _amount.sub(wAmount);
                
            factionWormholes[_planetID][_factionId].palladiumContributed = factionWormholes[_planetID][_factionId].palladiumContributed.add(wAmount);
                
            factionWormholes[_planetID][_factionId].repairContributed = factionWormholes[_planetID][_factionId].repairContributed.add(rAmount);
        }
        
        if(factionWormholes[_planetID][_factionId].palladiumContributed >= wormholeConstruction) {
            factionWormholes[_planetID][_factionId].created = true;
            factionWormholes[_planetID][_factionId].active = true;
        }
    }
    
    function rebuildWormhole(uint256 _planetID, uint256 _factionId, uint256 _amount) external {
        require(factionWormholes[_planetID][_factionId].created == true, "WORMHOLE NOT YET BUILT");
        require(factionWormholes[_planetID][_factionId].active == false, "WORMHOLE IS NOT DEPLETED");
        
        burnPalladium(msg.sender, _amount);
        
        bool cValue = factionWormholes[_planetID][_factionId].repairContributed.add(_amount) > wormholeRebuild;
        
        if(cValue == false) {
            factionWormholes[_planetID][_factionId].repairContributed = factionWormholes[_planetID][_factionId].repairContributed.add(_amount);
        }
        
        if(cValue == true) {
            factionWormholes[_planetID][_factionId].repairContributed = factionWormholes[_planetID][_factionId].repairContributed.add(_amount);
            factionWormholes[_planetID][_factionId].active = true;
            factionWormholes[_planetID][_factionId].repairContributed = factionWormholes[_planetID][_factionId].repairContributed.sub(wormholeRebuild);
        }
    }
    
    function declareWar(uint256 _planetID, uint256 _factionId) external {
        require(factionWormholes[_planetID][_factionId].active == true, "WORMHOLE IS NOT ACTIVE TO THIS PLANET");
        uint256 wFaction = planets[_planetID].controllingFaction;
        require(block.timestamp >= warStats[_planetID][wFaction].lastTimeSeiged.add(warCooldown), "PLANET IS NOT YET ELIGIBLE FOR A WAR");
        
        if(planets[_planetID].controllingFaction == 0) {
            planets[_planetID].controllingFaction = _factionId;
        }
        
        if(planets[_planetID].controllingFaction != 0) {
            warStats[_planetID][_factionId].currentlyContested = true;
            warStats[_planetID][planets[_planetID].controllingFaction].currentlyContested = true;
            planets[_planetID].contestingFaction = _factionId;
        }
        
    }
    
    function warContribution(uint256 _planetID, uint256 _factionId, uint256 _secondary) external {
        require(warStats[_planetID][_factionId].currentlyContested = true, "WAR IS NOT ACTIVE ON THIS PLANET");
        require(secondaryOwned[msg.sender] >= _secondary, "INSUFFCIENT RESOURCES");
        
        bool cAmount = warStats[_planetID][_factionId].secondaryContribution.add(_secondary) > secondaryRequirement;
        
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
            if(_factionId == planets[_planetID].controllingFaction) {
                uint256 lFaction = planets[_planetID].contestingFaction;
                
                warStats[_planetID][_factionId].currentlyContested = false;
                warStats[_planetID][lFaction].currentlyContested = false;
                factionWormholes[_planetID][lFaction].active = false;
                warStats[_planetID][_factionId].lastTimeSeiged = block.timestamp;
                planets[_planetID].contestingFaction = 0;
                
            } else 
            if(_factionId != planets[_planetID].controllingFaction) {
                uint256 lFaction = planets[_planetID].controllingFaction;
                
                planets[_planetID].controllingFaction = _factionId;
                warStats[_planetID][lFaction].rewardEndTime = block.timestamp;
                warStats[_planetID][_factionId].currentlyContested = false;
                warStats[_planetID][lFaction].currentlyContested = false;
                factionWormholes[_planetID][lFaction].active = false;
                warStats[_planetID][_factionId].lastTimeSeiged = block.timestamp;
                planets[_planetID].contestingFaction = 0;
            }
        }
    }
    
    function startMining(uint256 _tokenId, uint256 _factionId, uint256 _planetId) public {
        require(IERC721(unespiedMinter).ownerOf(_tokenId) == msg.sender, "YOU DO NOT OWN THIS NFT");
        
        if(workPass[_tokenId].faction == 0) {
            workPass[_tokenId].faction = _factionId;
        }
        
        require(planets[_planetId].controllingFaction == workPass[_tokenId].faction, "YOUR FACTION DOES NOT CONTROL THIS PLANET");
        
        if(workPass[_tokenId].faction !=0) {
            workPass[_tokenId].previousPlanet = workPass[_planetId].planetWorking;
            workPass[_tokenId].planetWorking = _planetId;
            workPass[_tokenId].planetStartTime = block.timestamp;
        }
    }

    function startMultis(uint256[] calldata _tokenIds, uint256[] calldata _factionIds, uint256[] calldata _planetIds ) external {
        require(_tokenIds.length == _factionIds.length && _tokenIds.length == _planetIds.length, "INCORRECT DATA STRUCTURE PROVIDED");

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            startMining(_tokenIds[i], _factionIds[i], _planetIds[i]);
        }
    }
    
    function collectSingleReward(uint256 _tokenId) external {
        require(IERC721(unespiedMinter).ownerOf(_tokenId) == msg.sender, "YOU DO NOT OWN THIS NFT");
        require(pauseRewards == false, "REWARD CLAIMING IS PAUSED");
        
        uint256[] memory rewardsDue = calculatePending(_tokenId);
        
        workPass[_tokenId].lastClaimed = block.timestamp;
        _mint(msg.sender, rewardsDue[0]);
        secondaryOwned[msg.sender] = secondaryOwned[msg.sender].add(rewardsDue[1]);
        
    }
    
    function collectAllRewards(uint256[] memory _tokenIds) external {
        
        require(pauseRewards == false, "REWARD CLAIMING IS PAUSED");
        
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            require(IERC721(unespiedMinter).ownerOf(_tokenIds[i]) == msg.sender, "YOU DO NOT OWN THIS NFT");
            
            uint256[] memory rewardsDue = calculatePending(_tokenIds[i]);
        
            workPass[_tokenIds[i]].lastClaimed = block.timestamp;
            _mint(msg.sender, rewardsDue[0]);
            secondaryOwned[msg.sender] = secondaryOwned[msg.sender].add(rewardsDue[1]);
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
    
    function calculatePending(uint256 _tokenId) public view returns(uint256[] memory) {
        uint256 cPlanet = workPass[_tokenId].planetWorking;
        uint256 oPlanet = workPass[_tokenId].previousPlanet;
        uint256 rEnd = warStats[cPlanet][workPass[_tokenId].faction].rewardEndTime;
        uint256 sTime = workPass[_tokenId].planetStartTime;
        uint256 lClaim = workPass[_tokenId].lastClaimed;
        uint256[] memory rewardsDue = new uint256[](2);
        
        if(cPlanet == 0) {
            rewardsDue[0] = 0;
            rewardsDue[1] = 0;
            return rewardsDue;
        }
        
        if(planets[cPlanet].controllingFaction != workPass[_tokenId].planetWorking) {
            uint256 oReward;
            uint256 cReward;
            uint256 oSecond;
            uint256 cSecond;
            
            oReward = planets[cPlanet].palladiumRates.mul(rEnd.sub(sTime)).div(86400);
            cReward = planets[oPlanet].palladiumRates.mul(block.timestamp.sub(rEnd)).div(86400);
            
            oSecond = planets[cPlanet].secondaryRates.mul(rEnd.sub(sTime)).div(86400);
            cSecond = planets[oPlanet].secondaryRates.mul(block.timestamp.sub(rEnd)).div(86400);
            
            rewardsDue[0] = oReward.add(cReward);
            rewardsDue[1] = oSecond.add(cSecond);
            
            return rewardsDue;
            
        }
        
        if(lClaim == 0) {
            rewardsDue[0] = planets[cPlanet].palladiumRates.mul(block.timestamp.sub(sTime)).div(86400);
            rewardsDue[1] = planets[cPlanet].secondaryRates.mul(block.timestamp.sub(sTime)).div(86400);
            
            return rewardsDue;
        } else
        if(lClaim != 0) {
            rewardsDue[0] = planets[cPlanet].palladiumRates.mul(block.timestamp.sub(lClaim)).div(86400);
            rewardsDue[1] = planets[cPlanet].secondaryRates.mul(block.timestamp.sub(lClaim)).div(86400);
            
            return rewardsDue;
        }
        
        return rewardsDue;
    }
    
}
