// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

//Internal Report for openzeppelin 
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarketplace is ERC721URIStorage{
    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    address payable owner;
    uint256 listingPrice = 0.025 ether;

    mapping (uint256 => MarketItem) private idMarketItem;

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    event idMarketItemCreated(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    modifier onlyOwner(){
        require(msg.sender == owner, "only Owner of the marketplace can change the listing price");
        _;
    }
    
    constructor() ERC721("NFT Metaverse Token", "MyNFT"){
        owner == payable(msg.sender);
    }

    function updateListingPrice(uint256 _listingPrice) public payable onlyOwner {
        listingPrice = _listingPrice;
    }

    function getListingPrice() public view returns(uint256) {
        return listingPrice;
    }

    function createToken(string memory tokenURI, uint256 price) public payable returns(uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender,newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        createMarketItem(newTokenId, price);
        return newTokenId;
    }
    function createMarketItem(uint256 tokenId, uint256 price) private {
        require(price > 0, "price cannot be zero");
        require(msg.value == listingPrice, "Price must be equal to listing price");

        idMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );
        _transfer(msg.sender, address(this), tokenId);
        emit idMarketItemCreated(tokenId, address(this), msg.sender, price, false);
    }
    //when someone have bought item and want to resale 
    function resellToken( uint256 tokenId, uint256 price) payable public {
        require(price > 0 , "price cannot be zero");
        require(idMarketItem[tokenId].owner == msg.sender, "You have to be owner of this item to resale it");
        require(msg.value == listingPrice, "price have to be equal to listing price");

        idMarketItem[tokenId].sold= false;
        idMarketItem[tokenId].price= price;
        idMarketItem[tokenId].seller= payable(msg.sender);
        idMarketItem[tokenId].owner= payable(address(this));

        _itemsSold.decrement();
        _transfer(msg.sender, address(this), tokenId);
        
    }

    //Will be trigerred when someone wants to buy an item
    function createMarketSale(uint256 tokenId) public payable{
        uint256 price= idMarketItem[tokenId].price;
        require(price == msg.value, "please submit the asking price in order to complete the purchase");

        idMarketItem[tokenId].sold= true;
        idMarketItem[tokenId].owner = payable(msg.sender);

        _itemsSold.increment();
        _transfer( address(this), msg.sender, tokenId);

        payable(owner).transfer(listingPrice);
        payable(idMarketItem[tokenId].seller).transfer(msg.value);
    }
    //Fetch all the NFTs which are listed in marketplace and are not sold yet
    function fetchMarketItem() public view returns (MarketItem [] memory) {
        uint256 itemCount = _tokenIds.current();
        uint256 unsoldItemCount = itemCount - _itemsSold.current();
        uint256 currentIndex = 0;
        MarketItem [] memory items= new MarketItem[](unsoldItemCount);

        for(uint256 i=1; i<= itemCount; i++){
            if(idMarketItem[i].owner == address(this)){
                MarketItem storage currentItem = idMarketItem[i];
                items[currentIndex]= currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    //fetch NFTs which belong to particular address
    function fetchMyNFT()public view returns(MarketItem[] memory){
        uint256 totalItems = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for(uint256 i=1; i <= totalItems; i++){
            if(idMarketItem[i].owner == msg.sender){
                itemCount +=1;
            }
        }
            MarketItem[] memory items = new MarketItem[](itemCount);
            for(uint256 i=1; i<= itemCount; i++){
                if(idMarketItem[i].owner == msg.sender){
                    MarketItem storage currentItem = idMarketItem[i];
                    items[currentIndex] = currentItem;
                    currentIndex +=1;
                }
            }
        return items;
    }

    //fetch NFTs which are listed for sale
    function fetchItemsListed()public view returns(MarketItem[] memory){
        uint256 totalItems = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for(uint256 i=1; i <= totalItems; i++){
            if(idMarketItem[i].seller == msg.sender){
                itemCount +=1;
            }
        }
            MarketItem[] memory items = new MarketItem[](itemCount);
            for(uint256 i=1; i<= itemCount; i++){
                if(idMarketItem[i].seller == msg.sender){
                    MarketItem storage currentItem = idMarketItem[i];
                    items[currentIndex] = currentItem;
                    currentIndex +=1;
                }
            }
        return items;
    }
}

