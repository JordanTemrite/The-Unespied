// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./PaymentSplitter.sol";
import "./ERC721Enumerable.sol";

contract TheUnespied is ERC721Enumerable, Ownable, PaymentSplitter {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Address for address;
    
    Counters.Counter private _tokenIdCounter;
    
    struct EspyenData {
        string name;
        string bio;
    }
    
    string private _baseURIextended;
    
    address payable thisContract;
    
    bool public publicSale = false;
    bool public whitelistSale = false;
    
    uint256 public mintPrice = .1 ether;
    uint256 public nameChangePrice = 75 ether;
    uint256 public bioChangePrice = 250 ether;
    
    uint256 public maxMint = 10000;
    uint256 public maxPer = 2;
    
    mapping(uint256 => EspyenData) public espyenData;
    mapping(address => uint256) public whiteList;
    mapping(address => uint256) public mintedAmount;
    
    address[] private _team = [
        0xab697c933e118794B89E89dD9f9998603eB85D2D
        ];
    
    uint256[] private _teamShares = [
        100
        ];
        
    event nameChanged(uint256 _tokenId, string newName);
    event bioChanged(uint256 _tokenId, string newBio);
        
    constructor() ERC721("Collection", "TICKER") PaymentSplitter(_team, _teamShares) {
        
    }
    
    fallback() external payable {
        
    }
    
    function withdrawAll() external onlyOwner {
        for (uint256 i = 0; i < _team.length; i++) {
            address payable wallet = payable(_team[i]);
            release(wallet);
        }
    }
    
    function setNamePrice(uint256 _newPrice) external onlyOwner {
        nameChangePrice = _newPrice;
    }
    
    function setBioPrice(uint256 _newPrice) external onlyOwner {
        bioChangePrice = _newPrice;
    }
    
    function setMintPrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }
    
    function setContract(address payable _contract) external onlyOwner {
        thisContract = _contract;
    }
    
    function setMax(uint256 _amount) external onlyOwner {
        maxMint = _amount;
    }
    
    function setMaxPer(uint256 _amount) external onlyOwner {
        maxPer = _amount;
    }
    
    function setPublicSale() external onlyOwner {
        publicSale = !publicSale;
    }
    
    function setWhitelistSale() external onlyOwner {
        whitelistSale = !whitelistSale;
    }
    
    function populateWhiteList(address[] memory _address, uint256[] memory _amount) external onlyOwner {
        
        require(_address.length == _amount.length, "INCORRECT DATA STRUCTURE");
        
        for(uint256 i = 0; i < _address.length; i++) {
            whiteList[_address[i]] = _amount[i];
        }
    }
    
    function changeName(uint256 _tokenId, string memory _name) external {
        
        require(msg.sender == ownerOf(_tokenId), "YOU DO NOT OWN THIS NFT");
        bytes memory name = bytes(_name);
        require(name.length > 0 && name.length < 25, "NAME TOO LONG");
        require(sha256(name) != sha256(bytes(espyenData[_tokenId].name)), "SAME AS CURRENT NAME");
        
        espyenData[_tokenId].name = _name;
        emit nameChanged(_tokenId, _name);
    }
    
    function changeBio(uint256 _tokenId, string memory _bio) external {
        
        require(msg.sender == ownerOf(_tokenId), "YOU DO NOT OWN THIS NFT");
        
        espyenData[_tokenId].bio = _bio;
        emit bioChanged(_tokenId, _bio);
    }
    
    function mintEspyen(uint256 _amount) external payable {
        
        require(msg.value == calcPrice(_amount), "SEND EXACT AMOUNTS");
        require(thisContract.send(msg.value) , "VALUE MUST BE SENT TO THE CONTRACT ADDRESS");
        require(_tokenIdCounter.current().add(_amount) <= maxMint, "MINT WOULD EXCEED MAX SUPPLY");
        require(publicSale == true || whitelistSale == true, "SALE IS INACTIVE");
        
        if(whitelistSale == true) {
            require(_amount <= whiteList[msg.sender], "NOT WHITELISTED OR EXCEEDING WHITELISTED AMOUNT");
            
            for(uint256 i = 0; i < _amount; i++) {
                whiteList[msg.sender] = whiteList[msg.sender].sub(1);
                _safeMint(msg.sender, _tokenIdCounter.current().add(1));
                _tokenIdCounter.increment();
            }
        }
        
        if(publicSale == true) {
            require(_amount.add(mintedAmount[msg.sender]) <= maxPer, "ATTEMPTING TO MINT PAST ALLOTMENT");
            
            for(uint256 i = 0; i < _amount; i++) {
                mintedAmount[msg.sender] = mintedAmount[msg.sender].add(1);
                _safeMint(msg.sender, _tokenIdCounter.current().add(1));
                _tokenIdCounter.increment();
            }
        }
    }
    
    function viewOwned(address owner) external view returns(uint256[] memory) {
        uint256 balance = balanceOf(owner);

        uint256[] memory IDs = new uint256[](balance);
        for(uint256 i; i < balance; i++){
            IDs[i] = tokenOfOwnerByIndex(owner, i);
        }
        return IDs;
    }
    
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }
    
    function viewThisContract() external view returns(address) {
        return thisContract;
    }
    
    
    function totalSupply() public view override returns(uint256) {
        return _tokenIdCounter.current();
    }
    
    function calcPrice(uint256 _amount) public view returns(uint256) {
        return mintPrice.mul(_amount);
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
    
}
