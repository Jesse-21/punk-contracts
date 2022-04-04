// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../../interfaces/IPunkTLD.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract KlimaPunkDomains is Ownable, ReentrancyGuard {
  bool public paused = true;

  address public gwamiContractAddress; // contract that does BCT buying, sKLIMA staking and KLIMA bonding

  uint256 public price; // domain price in USDC (6 decimals!!!)
  uint256 public royaltyFee = 2_000; // share of each domain purchase (in bips) that goes to Punk Domains
  uint256 public referralFee = 1_000; // share of each domain purchase (in bips) that goes to the referrer
  uint256 public constant MAX_BPS = 10_000;

  mapping (address => bool) public whitelisted; // addresses whitelisted for a free mint

  // USDC contract
  IERC20 public immutable usdc;

  // TLD contract
  IPunkTLD public immutable tldContract;

  // CONSTRUCTOR
  constructor(
    address _gwamiContractAddress,
    address _tldAddress,
    address _usdcAddress,
    uint256 _price
  ) {
    gwamiContractAddress = _gwamiContractAddress;
    tldContract = IPunkTLD(_tldAddress);
    usdc = IERC20(_usdcAddress);
    price = _price;
  }

  /// @notice A USDC approval transaction needs to be made before minting
  function mint(
    string memory _domainName,
    address _domainHolder,
    address _referrer
  ) external nonReentrant returns(uint256) {
    require(!paused || msg.sender == owner(), "Minting paused");

    // if msg.sender is whitelisted for a free mint, allow it (and set free mint back to false)
    if (whitelisted[msg.sender]) {
      // free minting
      whitelisted[msg.sender] = false;
    } else {
      // paid minting (distribute the payment)
      uint256 royaltyPayment = (price * royaltyFee) / MAX_BPS;
      uint256 gwamiPayment = price - royaltyPayment;

      if (referralFee > 0 && _referrer != address(0)) {
        uint256 referralPayment = (price * referralFee) / MAX_BPS;
        gwamiPayment = gwamiPayment - referralPayment;
        usdc.transferFrom(msg.sender, _referrer, referralPayment);
      }
      
      usdc.transferFrom(msg.sender, tldContract.getFactoryOwner(), royaltyPayment);
      usdc.transferFrom(msg.sender, gwamiContractAddress, gwamiPayment);
    }

    return tldContract.mint{value: 0}(_domainName, _domainHolder, address(0));
  }

  // OWNER

  function addAddressToWhitelist(address _addr) external onlyOwner {
    whitelisted[_addr] = true;
  }

  function changeGwamiContractAddress(address _newGwamiAddr) external onlyOwner {
    gwamiContractAddress = _newGwamiAddr;
  }

  function changeMaxDomainNameLength(uint256 _maxLength) external onlyOwner {
    tldContract.changeNameMaxLength(_maxLength);
  }

  /// @notice This changes price in the wrapper contract
  function changePrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  /// @notice This changes referral fee in the wrapper contract
  function changeReferralFee(uint256 _referral) external onlyOwner {
    referralFee = _referral;
  }

  /// @notice This changes description in the .klima TLD contract
  function changeTldDescription(string calldata _description) external onlyOwner {
    tldContract.changeDescription(_description);
  }

  /// @notice Recover any ERC-20 tokens that were mistakenly sent to the contract
  function recoverERC20(address tokenAddress_, uint256 tokenAmount_, address recipient_) external onlyOwner {
    IERC20(tokenAddress_).transfer(recipient_, tokenAmount_);
  }

  /// @notice Recover any ERC-721 tokens that were mistakenly sent to the contract
  function recoverERC721(address tokenAddress_, uint256 tokenId_, address recipient_) external onlyOwner {
    IERC721(tokenAddress_).transferFrom(address(this), recipient_, tokenId_);
  }

  /// @notice Transfer .klima TLD ownership to another address
  function transferTldOwnership(address _newTldOwner) external onlyOwner {
    tldContract.transferOwnership(_newTldOwner);
  }

  function togglePaused() external onlyOwner {
    paused = !paused;
  }

  /// @notice Withdraw MATIC from the contract
  function withdraw() external onlyOwner {
    (bool success, ) = owner().call{value: address(this).balance}("");
    require(success, "Failed to withdraw ETH from contract");
  }

  // RECEIVE & FALLBACK
  receive() external payable {}
  fallback() external payable {}
}