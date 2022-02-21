pragma solidity ^0.8.4;

//importing ERC721 contract
import "../node_modules/@OpenZeppelin/contracts/token/ERC721/ERC721.sol";
//importing ERC721 extension/metadata_extention
import "../node_modules/@OpenZeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
//importing Counters.sol Lib
import "../node_modules/@OpenZeppelin/contracts/utils/Counters.sol";


//inheriting ERC721URIStorage, which has inherited ERC721
contract NFT is ERC721URIStorage {
	//using Counter Lib
	//Assign all funcs in Counters Lib to Counters.Counter
	//Counters.Counter is a Struct
    using Counters for Counters.Counter;

    // unique Token IDs
    Counters.Counter private _tokenIds;
    // address of the marketplace contract
    address marketplaceAddress;

    // passing address of the marketplace, with which the NFT can interact.
    // The marketplace will only have the access to change the ownerships of the NFTS
    constructor(address _marketplaceAddress) ERC721("W3dev Token", "W3T"){
    	marketplaceAddress = _marketplaceAddress;
    }


    // minting tokens
    // returns Token ID
    function createToken (string memory tokenURI) public returns (uint) {
    	_tokenIds.increment(); // increment the Token ID
    	uint256 newId = _tokenIds.current(); // setting newId to the current Token ID

    	_mint(msg.sender, newId) // mint Token
    	_setTokenURI(newId, tokenURI) // for setting link to MetaData of the Token

    	//Approve from the marketplace
    	setApprovalforAll(marketplaceAddress, true);
    	return newId; 
    	
    }
    

}