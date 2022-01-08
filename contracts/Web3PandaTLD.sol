// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "./lib/strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Web3PandaTLD is ERC721, Ownable {
  using strings for string;

  // STATE
  uint256 public price; // price (how much a user needs to pay for a domain)
  bool public buyingEnabled; // buying domains enabled (true/false)
  address public factoryAddress; // Web3PandaTLDFactory address
  uint256 public royaltyPercentage; // percentage of each domain purchase that goes to Web3Panda DAO
  uint256 public totalSupply;
  uint256 public nameMaxLength = 140; // the maximum length of a domain name

  // domain data struct
  struct Domain {
    string name; // domain name that goes before the TLD name; example: "tempetechie" in "tempetechie.web3"
    uint256 tokenId; // domain token ID
    address holder; // domain holder address

    string description; // optional: description that domain holder can add
    string url; // optional: domain holder can specify a URL that his domain redirects to

    // optional: domain holder can set up a profile picture (an NFT that they hold)
    address pfpAddress;
    uint256 pfpTokenId;
  }
  
  mapping (string => Domain) public domains; // mapping (domain name => Domain struct)
  mapping (uint256 => string) public domainIdsNames; // mapping (tokenId => domain name)

  // EVENTS
  event DomainCreated(address indexed user, address indexed owner, string indexed fullDomainName);
  event PfpValidated(address indexed user, address indexed owner, bool valid);

  // MODIFIERS
  modifier validName(string memory _name) {
    require(
      strings.len(strings.toSlice(_name)) > 1,
      "The domain name must be longer than 1 character"
    );

    require(
      bytes(_name).length < nameMaxLength,
      "The domain name is too long"
    );

    require(
      strings.count(strings.toSlice(_name), strings.toSlice(".")) == 0,
      "There should be no dots in the name"
    );

    require(domains[_name].holder == address(0), "Domain with this name already exists");
    
    _;
  }

  // CONSTRUCTOR
  constructor(
    string memory _name,
    string memory _symbol,
    address _tldOwner,
    uint256 _domainPrice,
    bool _buyingEnabled,
    uint256 _royalty,
    address _factoryAddress
  ) ERC721(_name, _symbol) {
    price = _domainPrice;
    buyingEnabled = _buyingEnabled;
    royaltyPercentage = _royalty;
    factoryAddress = _factoryAddress;

    transferOwnership(_tldOwner);
  }

  // READ

  // get domain holder's address
  // get domain holder's profile image (NFT address and token ID)

  // function tokenURI(uint256) public view override returns (string memory)

  // WRITE

  function mint(
    string memory _domainName, 
    address _domainOwner
    // TODO: description
    // TODO: url
    // TODO: pfp
  ) public payable {
    require(buyingEnabled == true, "Buying TLDs is disabled");
    require(msg.value >= price, "Value below price");

    _mintDomain(_domainName, _domainOwner);
  }

  function _mintDomain(
    string memory _domainName, 
    address _domainOwner
    // TODO: description
    // TODO: url
    // TODO: pfp
  ) internal validName(_domainName) {
    uint tokId = totalSupply;
    totalSupply++;

    _safeMint(_domainOwner, tokId);

    string memory fullDomainName = string(abi.encodePacked(_domainName, name()));

    Domain memory newDomain;

    newDomain.name = _domainName;
    newDomain.tokenId = tokId;
    newDomain.holder = _domainOwner;

    // TODO: description, url, pfp

    // add to both mappings
    domains[_domainName] = newDomain;
    domainIdsNames[tokId] = _domainName;
    
    emit DomainCreated(msg.sender, _domainOwner, fullDomainName);
  }

  /**
    * @dev Hook that is called before any token transfer. This includes minting
    * and burning.
    */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override virtual {

    if (from != address(0)) { // this runs on every transfer but not on mint
      // change holder address in struct data (URL and description stay the same)
      domains[domainIdsNames[tokenId]].holder = to;
    }

    // call the function that checks if holder of that tokenId owns their chosen pfp
    // this function runs on minting, too
    validatePfp(tokenId, to);
  }

  // check if holder of a domain (based on domain token ID) still owns their chosen pfp
  // anyone can do this validation for any user
  function validatePfp(uint256 _tokenId, address _user) public {
    address pfpAddress = domains[domainIdsNames[_tokenId]].pfpAddress;

    if (pfpAddress != address(0)) {
      uint256 pfpTokenId = domains[domainIdsNames[_tokenId]].pfpTokenId;

      ERC721 pfpContract = ERC721(pfpAddress); // get PFP contract

      if (pfpContract.ownerOf(pfpTokenId) != _user) {
        // if user does not own that PFP, delete the PFP address from user's Domain struct 
        // (PFP token ID can be left alone to save on gas)
        domains[domainIdsNames[_tokenId]].pfpAddress = address(0);
        emit PfpValidated(msg.sender, _user, false);
      } else {
        emit PfpValidated(msg.sender, _user, true); // PFP image is valid
      }
    }
    
  }

  // OWNER

  // function: create a new domain for a specified address for free

  // change the payment amount for a new domain
  function changePrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  // enable/disable buying domains (except for the owner)
  function toggleBuyingDomains() public onlyOwner {
    buyingEnabled = !buyingEnabled;
  }
  
  // change nameMaxLength (max length of a TLD name)
  function changeNameMaxLength(uint256 _maxLength) public onlyOwner {
    nameMaxLength = _maxLength;
  }
  
  // FACTORY OWNER (current owner address of Web3PandaTLDFactory)

  // function: change percentage of each domain purchase that goes to Web3Panda DAO
}
