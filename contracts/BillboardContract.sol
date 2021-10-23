//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;



import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
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
   address mainCompany;
   
   
   address[] companies;
   mapping(address => bool) public isCompany;
   
   // map company to weth _amount
   mapping(address => uint256) public companyBalance;
   
   
   address[] foundingMembers;
   mapping(address => bool) isFoundingMember;
   mapping(address => uint256) public foundingMemberBalance;
   
   
   //mapping for companyPoolShare
   uint256 public mainCompanyBalance;
   
   // contract weth allocation-
   
   uint256 public collectiveContractBalance;
   
   
   
   
   IERC20 wethInstance = IERC20(wethRinkeby);
   
   address admin;
   
   //Media.sol constructor
   constructor()public{
       admin = msg.sender;
       mainCompany = msg.sender;
   }
   
   function viewAdmin()public view returns(address){
       return admin;
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
    
    
    // this functionality implements the setAsk for multiple Media in a single function call
    function batchSetSale(uint256 _amount, uint256[] memory _tokenIds) public{
        
        for(uint256 i=0; i< _tokenIds.length; i++){
            IMarket.Ask memory saleCondition = IMarket.Ask(_amount, wethRinkeby);
            MediaContract.setAsk(_tokenIds[i], saleCondition);
            
        }
        
    }
    
    
    function bidForToken(uint256 _tokenId, uint256 _amount, address _tokenAddress ) public {
       // address owner = MediaContract.previousTokenOwners(_tokenId);
       
        IMarket.Bid memory bidProposal = IMarket.Bid(_amount, _tokenAddress, msg.sender, msg.sender, Decimal.D256(0)); 
        MediaContract.setBid(_tokenId, bidProposal);
    }
    
    
    function approveBid(uint256 _amount, uint256 _tokenId, address _tokenAddress) public{
        IMarket.Bid memory bidProposed = IMarket.Bid(_amount, _tokenAddress, msg.sender, msg.sender, Decimal.D256(0)); 
        MediaContract.acceptBid(_tokenId, bidProposed);
        splitOnFirstSale();
    }
    
    
    function addCompanyAddress(address _newCompany)public {
      //  require(msg.sender == admin, 'only admin can call this function');
        companies.push(_newCompany);
        isCompany[_newCompany] = true;
        
    }
    
    function addFoundingMember(address _newMember) public{
     //   require(msg.sender == admin, 'only admin can call this function');
        foundingMembers.push(_newMember);
        isFoundingMember[_newMember] = true;
    }
    
    
    // returns entire weth balance of contract
    function wethBalanceOfContract() public view returns(uint256){
        return wethInstance.balanceOf(address(this));
    }
    
    
    // individual companies can withdraw thier earnings so far
    function withdrawCompanyEarning(address _companyAddress) public {
        require(isCompany[_companyAddress] == true, 'this address is not on the list of the companies');
        require(msg.sender == _companyAddress, 'You cannot withdraw on behalf of another company address');
        require(companyBalance[_companyAddress] > 0, 'your balance is currently zero');
        companyBalance[_companyAddress] = 0;
        wethInstance.transfer(_companyAddress, companyBalance[_companyAddress]);
    }
    
    // founding teams can withdraw thier earnings so far
    function withdrawFoundingMemberBalance(address _member)public{
        require(isFoundingMember[_member] == true, 'this address is not on the list of founding members');
        require(msg.sender == _member, 'you cannot withdraw on behalf of another founding member');
        require(foundingMemberBalance[_member] > 0, 'your balance is currently zero');
        foundingMemberBalance[_member] = 0;
        wethInstance.transfer(_member, foundingMemberBalance[_member]);
        
    }
    
    function mainCompanyWithdraw()public{
        require(msg.sender == mainCompany, 'only the address of the main company can do this');
        mainCompanyBalance = 0;
        wethInstance.transfer(msg.sender, mainCompanyBalance);
    }
    
    // function to split- its an internal function
    function splitOnFirstSale() internal {
        // calculate portions for company Pool, main company and collectives
        uint256 amountToSplit = wethInstance.balanceOf(address(this));
        uint256 mainCompanyShare = amountToSplit * 90/100; 
        uint256 companyPoolShare = amountToSplit * 10/100;
        uint256 foundingMembersShare = amountToSplit * 5/100;
        uint256 collectiveContractShare = amountToSplit * 5/100;
        
        // update main company balance
        mainCompanyBalance = mainCompanyShare;
        collectiveContractBalance = collectiveContractShare;
        
        
        for(uint256 i = 0; i<companies.length; i++){
            // 
            companyBalance[companies[i]] = companyPoolShare / companies.length;
            
        }
        
        
        for(uint256 j = 0; j < foundingMembers.length; j++){
            foundingMemberBalance[foundingMembers[j]] = foundingMembersShare/foundingMembers.length;
        }
        
    
        
    }
    
    function withdrawCollectiveBalance()public{
        //   require(msg.sender == admin, 'only admin can call this function');
        collectiveContractBalance = 0;
        wethInstance.transfer(msg.sender, collectiveContractBalance);
        
    }
    
}