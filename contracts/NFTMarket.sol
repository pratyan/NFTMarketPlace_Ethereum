pragma solidity ^0.8.4;

//importing ERC721 contract
import "../node_modules/@OpenZeppelin/contracts/token/ERC721/ERC721.sol";
//importing Counters.sol Lib
import "../node_modules/@OpenZeppelin/contracts/utils/Counters.sol";
// For security Protocol
import "../node_modules/@OpenZeppelin/contracts/security/ReentrancyGuard.sol";
//importing IERC721 contract for transfer method
import "../node_modules/@OpenZeppelin/contracts/token/ERC721/IERC721.sol";


// inheriting ReetrancyGuard to use its funcs for security 
contract NFTMarket is ReentrancyGuard {
	//using Counter Lib
	//Assign all funcs in Counters Lib to Counters.Counter
	//Counters.Counter is a Struct
    using Counters for Counters.Counter;

    Counters.Counter private _itemIds; // for unique Token IDs
    Counter.Counter private _itemsSold; // for tracking no. sold NFTs

    // address of owner of this marketplace
    // 'payable' -> as the owner going to get commission for every trade
    address payable owner;
    // setting the listing price
    uint256 listingPrice = 0.001 ether;

    // setting the owner = contract deployer
    constructor() {
    	owner = payable(msg.sender);
    }


    //structure of items
    struct MarketItem {
    	uint itemId;
    	address nftContract;
    	uint256 tokenId;
    	address payable seller;
    	address payable owner;
    	uint256 price;
    	bool sold;
    }

    // mapping item Id to the items
    mapping(uint256 => MarketItem) private idToMarketItem;


    // event for every new item created
    event MarketItemCreated (
    	uint indexed itemId,
    	address indexed nftContract,
    	uint256 indexed tokenId,
    	address seller,
    	address owner,
    	uint256 price,
    	bool sold
    );

    //to get the listing price
    function  getListingPrice() public view returns (uint256) {
    	return listingPrice;
    }

    //creating new Market Iteam Id
    //modifier nonReentrant from ReentrancyGuard
    function createMarketItem(address _nftContract, uint256 _tokenId, uint256 _price) public payable nonReentrant {
    	//Conditions
    	require(_price > 0, "Price must be at least greater than zero");
    	require(msg.value == listingPrice, "price must be equal to listing price");


    	_itemIds.increment(); //incrementing the no. of items
    	uint256 currentId = _itemIds.current(); // setting the current item Id

    	//mapping the new item created to its Id 
    	// setting owner to None/empty address
    	idToMarketItem[currentId] = MarketItem(currentId, _nftContract, _tokenId, payable(msg.sender), payable(address(0)), _price, false);

    	//transferring the ownership of the nft from the sender to this contract
    	IERC721(_nftContract).transferFrom(msg.sender, address(this), _tokenId);

    	// emit the event for creating new item
    	emit MarketItemCreated(currentId, _nftContract, _tokenId, msg.sender, _price, false);
    }


    // for saling items
    //modifier nonReentrant from ReentrancyGuard
    function createMarketSale(address _nftContract, uint256 _itemId) public payable nonReentrant {
    	uint _price = idToMarketItem[_itemId].price; // geeting the price from the mapped items
    	uint _tokenId = idToMarketItem[_itemId].tokenId; // geeting the token Id from the mapped items

    	//condition
    	require(msg.value == price, "Please submit the asking price");

    	// transfer the money to the seller
    	idToMarketItem[_itemId].seller.transfer(msg.value);

    	//updating the mapping
    	idToMarketItem[_itemId].owner = payable(msg.sender); //change the ownership
    	idToMarketItem[_itemId].sold = true; // sold

    	_itemsSold.increment(); // incrementing the no. iteams sold

    	payable(owner).transfer(listingPrice); // transfering listing fee to the owner of this marketplace
    }


    // fetch all market items
    function allItems() public view returns (MarketItem[] memory) {
    	uint totalItems = _itemIds.current(); //getting the total no. of market items
    	uint unsoldItems = totalItems - _itemsSold.current(); //no. of unsold items

    	//creating dynamic array for the market items
    	MarketItem[] memory items = new MarketItem[](unsoldItems);

    	// loop to append item to the array
    	for (uint i=0; i<totalItems; i++) {
    		//check if sold
    		if (idToMarketItem[i+1].sold == false) {
    			uint currentId = idToMarketItem[i+1].itemId; // fetch the item Id
    			// storing the item at current Id to currentItem
    			MarketItem storage currentItem = idToMarketItem[currentId]
    			// appending the item to the array
    			items[i] = currentItem;

    		}
    	}

    	return items; //return the array of the Market items
    }


    // fetch user's items
    function userItem() public view returns (MarketItem[] memory) {
    	uint totalItems = _itemIds.current(); //getting the total no. of market items
    	uint userItemCount = 0;

    	//iterating to find the no. of items the user posses
    	for (uint i=0; i<totalItems; i++) {
    		//checking if the owner of the item is the user
    		if (idToMarketItem[i+1].owner == msg.sender) {
    			userItemCount += 1; //increment the user item count
    		}
    	}

    	//creating dynamic array for the user's items
    	MarketItem[] memory items = new MarketItem[](userItemCount);

    	//iterating to append the items array with user's item
    	for (uint i=0; i<totalItems; i++) {
    		//checking if the owner of the item is the user
    		if (idToMarketItem[i+1].owner == msg.sender) {
    			// storing the item associated to this id,  to currentItem
    			MarketItem storage currentItem = idToMarketItem[idToMarketItem[i+1].itemId];
    			items[i] = currentItem; // appending the array
    		}
    	}

    	return items; // returns the required useritem array

    }


    // fetch user's created items
    function userCreatedItem () public view returns(MarketItem[] memory) {
    	uint totalItems = _itemIds.current(); //getting the total no. of market items
    	uint userCreatedItemCount = 0;

    	//iterating to find the no. of items the user created
    	for (uint i=0; i<totalItems; i++) {
    		//checking if the seller of the item is the user
    		if (idToMarketItem[i+1].seller == msg.sender) {
    			userCreatedItemCount += 1; //increment the user created item count
    		}
    	}

    	//creating dynamic array for the user's created items
    	MarketItem[] memory items = new MarketItem[](userCreatedItemCount);

    	//iterating to append the items array with user's created item
    	for (uint i=0; i<totalItems; i++) {
    		//checking if the seller of the item is the user
    		if (idToMarketItem[i+1].seller == msg.sender) {
    			// storing the item associated to this id,  to currentItem
    			MarketItem storage currentItem = idToMarketItem[idToMarketItem[i+1].itemId];
    			items[i] = currentItem; // appending the array
    		}
    	}

    	return items; // returns the required user created item array

    }
    


}
