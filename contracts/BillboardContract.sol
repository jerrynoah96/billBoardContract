// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@zoralabs/core/dist/contracts/interfaces/IMarket.sol";
import "@zoralabs/core/dist/contracts/interfaces/IMedia.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface ERC721Owner {
  function ownerOf(uint256 token) external view returns (address);
}

contract BillboardContract is IERC721Receiver, Initializable, OwnableUpgradeable {
  using SafeMath for uint256;

  address wethAddress;
  mapping(address => bool) public isAdmin;
  // zora contract on rinkeby
  IMedia MediaContract;
  IMarket MarketContract;

  ERC721Owner MediaOwner;

  IERC20 wethInstance;

  address mainAdmin;

  event ContractBalanceWithdrawn(address _to, uint256 _contractBal);

  modifier onlyAdmin() {
    require(
      isAdmin[msg.sender] == true,
      "only an admin can call this function"
    );
    _;
  }

  modifier onlyMainAdmin() {
    require(
      msg.sender == mainAdmin,
      "only the main admin can call this function"
    );
    _;
  }

  // Media.sol constructor
  function initialize(
    address _mainAdmin,
    address _mediaContractAddress,
    address _marketContractAddress,
    address _wethAddress
  ) public initializer {
    MediaContract = IMedia(_mediaContractAddress);
    MarketContract = IMarket(_marketContractAddress);
    MediaOwner = ERC721Owner(_mediaContractAddress);
    wethAddress = _wethAddress;
    wethInstance = IERC20(_wethAddress);
    mainAdmin = _mainAdmin;
    isAdmin[_mainAdmin] = true;
    OwnableUpgradeable.__Ownable_init();
  }

  function viewMainAdmin() public view returns (address) {
    return mainAdmin;
  }

  function addAdmin(address _newAdmin) public onlyMainAdmin {
    isAdmin[_newAdmin] = true;
  }

  function removeAdmin(address _adminAddress) public onlyMainAdmin {
    require(
      isAdmin[_adminAddress] == true,
      "this address is currently not an admin"
    );
    isAdmin[_adminAddress] = false;
  }

  function MintMedia(
    string memory tokenURI,
    string memory metadataURI,
    bytes32 contentHash,
    bytes32 metadataHash
  ) public onlyAdmin {
    IMedia.MediaData memory newData = IMedia.MediaData(
      tokenURI,
      metadataURI,
      contentHash,
      metadataHash
    );
    IMarket.BidShares memory bid_Share = IMarket.BidShares(
      Decimal.D256(0 * 10**18),
      Decimal.D256(15 * 10**18),
      Decimal.D256(85 * 10**18)
    );
    MediaContract.mint(newData, bid_Share);
  }

  function BatchMintMedia(
    string[] memory allTokenURI,
    string[] memory allMetadataURI,
    bytes32[] memory allContentHash,
    bytes32[] memory allMetadataHash
  ) public onlyAdmin returns (bool) {
    for (uint256 i = 0; i < allTokenURI.length; i++) {
      IMedia.MediaData memory newData = IMedia.MediaData(
        allTokenURI[i],
        allMetadataURI[i],
        allContentHash[i],
        allMetadataHash[i]
      );
      IMarket.BidShares memory bid_Share = IMarket.BidShares(
        Decimal.D256(0 * 10**18),
        Decimal.D256(15 * 10**18),
        Decimal.D256(85 * 10**18)
      );
      MediaContract.mint(newData, bid_Share);
    }
    return true;
  }

  function OwnerOfMedia(uint256 tokenId) public view returns (address) {
    address owner = MediaOwner.ownerOf(tokenId);
    return owner;
  }

  function MediaBidShares(uint256 tokenId)
    public
    view
    returns (IMarket.BidShares memory)
  {
    return MarketContract.bidSharesForToken(tokenId);
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  ) public virtual override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  // this functionality implements the set Ask in zora contracts
  function setToSale(uint256 _amount, uint256 _tokenId) public {
    IMarket.Ask memory saleCondition = IMarket.Ask(_amount, wethAddress);
    MediaContract.setAsk(_tokenId, saleCondition);
  }

  // this functionality implements the setAsk for multiple Media in a single function call
  function batchSetSale(uint256 _amount, uint256[] memory _tokenIds) public {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      IMarket.Ask memory saleCondition = IMarket.Ask(_amount, wethAddress);
      MediaContract.setAsk(_tokenIds[i], saleCondition);
    }
  }

  // function to see currentAsk on a tokenURI
  function currentAskPrice(uint256 tokenId) public view returns (uint256) {
    return MarketContract.currentAskForToken(tokenId).amount;
  }

  // returns entire weth balance of contract
  function wethBalanceOfContract() public view returns (uint256) {
    return wethInstance.balanceOf(address(this));
  }

  function withdrawContractBalance(address _wallet) public onlyMainAdmin {
    // get contract weth balance
    uint256 wethBal = wethInstance.balanceOf(address(this));
    wethInstance.transfer(_wallet, wethBal);

    emit ContractBalanceWithdrawn(_wallet, wethBal);


  }
}
