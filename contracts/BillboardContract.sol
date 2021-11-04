//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;



import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
//import  "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import '@zoralabs/core/dist/contracts/interfaces/IMarket.sol';
import '@zoralabs/core/dist/contracts/interfaces/IMedia.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


interface ERC721Owner {
  function ownerOf(uint256 token) external view returns (address);
}

contract BillboardContract is IERC721Receiver {
    
    using SafeMath for uint256;
    
  
   
   // zora contract on rinkeby
   IMedia MediaContract = IMedia(0x7C2668BD0D3c050703CEcC956C11Bd520c26f7d4); 
   IMarket MarketContract = IMarket(0x85e946e1Bd35EC91044Dc83A5DdAB2B6A262ffA6);
   
   ERC721Owner MediaOwner = ERC721Owner(0x7C2668BD0D3c050703CEcC956C11Bd520c26f7d4);
   
   // Weth address on rinkeby
   address wethRinkeby = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
  
   IERC20 wethInstance = IERC20(wethRinkeby);
   
   address admin;
   
   //Media.sol constructor
   constructor()public{
       admin = msg.sender;
   }
   
   function viewAdmin()public view returns(address){
       return admin;
   }
   
  
  
   function MintMedia(string memory tokenURI,
   string memory metadataURI, bytes32 contentHash, 
   bytes32 metadataHash) public{
      
       IMedia.MediaData memory newData = IMedia.MediaData(tokenURI, metadataURI, contentHash, metadataHash);
       IMarket.BidShares memory bid_Share = IMarket.BidShares(Decimal.D256(0* 10**18), Decimal.D256(100 * 10**18), Decimal.D256(0 * 10**18));
       MediaContract.mint(newData, bid_Share);
   }
   
   function BatchMintMedia(string[] memory allTokenURI,
   string[] memory allMetadataURI, bytes32[] memory allContentHash,
   bytes32[] memory allMetadataHash) public returns(bool){
     //  require(allTokenURI.length == allMetadataURI.length, 'unequal paramter lenghts');
       
       for(uint256 i = 0; i < allTokenURI.length; i++){
       
       IMedia.MediaData memory newData = IMedia.MediaData(allTokenURI[i], allMetadataURI[i], allContentHash[i], allMetadataHash[i]);
       IMarket.BidShares memory bid_Share = IMarket.BidShares(Decimal.D256(0 * 10**18), Decimal.D256(100 * 10**18), Decimal.D256(0 * 10**18));
       MediaContract.mint(newData, bid_Share);
       }
       return true;
   }
   
   
    
    function OwnerOfMedia(uint256 tokenId) public view returns(address){
        address owner = MediaOwner.ownerOf(tokenId);
        return owner;
    }
    
    
    function MediaBidShares(uint256 tokenId) public view returns(IMarket.BidShares memory){
        return MarketContract.bidSharesForToken(tokenId);
        
    }
    
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    

    // this functionality implements the set Ask in zora contracts for creator
    function setToSaleForCreator(uint256 _amount, uint256 _tokenId) public {
        IMarket.Ask memory saleCondition = IMarket.Ask(_amount, wethRinkeby);
        MediaContract.setAsk(_tokenId, saleCondition);
    }
    
    
    // this functionality is to set back to sale by previousTokenOwners
    // the bid share is also reset
    function reSale(uint256 _tokenId, uint256 _amount) public{
         IMarket.BidShares memory bid_Share = IMarket.BidShares(Decimal.D256(0 * 10**18), Decimal.D256(15 * 10**18), Decimal.D256(85 * 10**18));
        MarketContract.setBidShares(_tokenId, bid_Share);
        
        IMarket.Ask memory saleCondition = IMarket.Ask(_amount, wethRinkeby);
        MediaContract.setAsk(_tokenId, saleCondition);
    }
    
    
    // this functionality implements the setAsk for multiple Media in a single function call
    function batchSetSale(uint256 _amount, uint256[] memory _tokenIds) public{
        
        for(uint256 i=0; i< _tokenIds.length; i++){
            IMarket.Ask memory saleCondition = IMarket.Ask(_amount, wethRinkeby);
            MediaContract.setAsk(_tokenIds[i], saleCondition);
            
        }
        
    }
    
    // function to see currentAsk on a tokenURI
    function currentAskPrice(uint256 tokenId) public view returns(uint256) {
        return MarketContract.currentAskForToken(tokenId).amount;
    }
    
    
    // returns entire weth balance of contract
    function wethBalanceOfContract() public view returns(uint256){
        return wethInstance.balanceOf(address(this));
    }
    
    function withdrawContractBalance(address _wallet) public{
        wethInstance.transfer(_wallet, wethInstance.balanceOf(address(this)));
    }
    
   
}