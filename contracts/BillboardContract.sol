//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;



import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import '@zoralabs/core/dist/contracts/interfaces/IMarket.sol';
import '@zoralabs/core/dist/contracts/interfaces/IMedia.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';




contract BillboardContract is IERC721Receiver {
    
    using SafeMath for uint256;
    
   address[] public stakeHolders;
   
   // zora contract on rinkeby
   IMedia MediaContract = IMedia(0x7C2668BD0D3c050703CEcC956C11Bd520c26f7d4); 
   
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
   
  
   function addStakeHolder(address _newStakeHolder) public {
       require(msg.sender == admin, 'only admin can add stakeholder');
       stakeHolders.push(_newStakeHolder);
   }
   
  
   function MintMedia(string memory tokenURI,
   string memory metadataURI, string memory contentHash, 
   string memory metadataHash, uint256 creatorShare, uint256 ownerShare) public{
      
       bytes32 contentBytes32 = stringToBytes32(contentHash);
       bytes32 metadataBytes32 = stringToBytes32(metadataHash);
       IMedia.MediaData memory newData = IMedia.MediaData(tokenURI, metadataURI, contentBytes32, metadataBytes32);
       IMarket.BidShares memory bid_Share = IMarket.BidShares(Decimal.D256(0* 10**18), Decimal.D256(creatorShare * 10**18), Decimal.D256(ownerShare * 10**18));
       MediaContract.mint(newData, bid_Share);
  
   }
   
   function BatchMintMedia(string[] memory allTokenURI,
   string[] memory allMetadataURI, string[] memory allContentHash,
   string[] memory allMetadataHash, uint256[] memory creatorShares, 
   uint256[] memory ownerShares) public returns(bool){
     //  require(allTokenURI.length == allMetadataURI.length, 'unequal paramter lenghts');
       
       for(uint256 i = 0; i < allTokenURI.length; i++){
        bytes32 contentBytes32 = stringToBytes32(allContentHash[i]);
       bytes32 metadataBytes32 = stringToBytes32(allMetadataHash[i]);
       IMedia.MediaData memory newData = IMedia.MediaData(allTokenURI[i], allMetadataURI[i], contentBytes32, metadataBytes32);
       IMarket.BidShares memory bid_Share = IMarket.BidShares(Decimal.D256(0 * 10**18), Decimal.D256(creatorShares[i] * 10**18), Decimal.D256(ownerShares[i] * 10**18));
       MediaContract.mint(newData, bid_Share);
       }
       return true;
   }
   
   
   function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }

        assembly {
            result := mload(add(source, 32))
        }
    }
    
    
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    

    // this functionality implements the set Ask in zora contracts
    function setToSale(uint256 _amount, uint256 _tokenId) public {
        IMarket.Ask memory saleCondition = IMarket.Ask(_amount, wethRinkeby);
        MediaContract.setAsk(_tokenId, saleCondition);
    }
    
    
    function bidForToken(uint256 _tokenId, uint256 _amount, address _tokenAddress ) public {
       // address owner = MediaContract.previousTokenOwners(_tokenId);
       
        IMarket.Bid memory bidProposal = IMarket.Bid(_amount, _tokenAddress, msg.sender, msg.sender, Decimal.D256(0)); 
        MediaContract.setBid(_tokenId, bidProposal);
    }
    
    function approveBid(uint256 _amount, uint256 _tokenId, address _tokenAddress) public{
        IMarket.Bid memory bidProposed = IMarket.Bid(_amount, _tokenAddress, msg.sender, msg.sender, Decimal.D256(0)); 
        MediaContract.acceptBid(_tokenId, bidProposed);
    }
    
    
    
      function splitContractWEth()public payable{
        require(msg.sender == admin, 'only admin please');
        
        
        uint256 contractWEthBalance = wethInstance.balanceOf(address(this));

        //split contractWEthBalance equally among stakeHolders 
        for(uint256 i =0; i < stakeHolders.length; i++){
            
            payable(stakeHolders[i]).transfer(contractWEthBalance/stakeHolders.length);
        }
        
      }
        
        function wethBalanceOfContract() public view returns(uint256){
            return wethInstance.balanceOf(address(this));
        }
        
        
    }