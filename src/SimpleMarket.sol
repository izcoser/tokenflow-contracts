// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract SimpleMarket is Ownable {
    error NotOwnerOfToken(address, uint256, address);
    error TokenNotApproved(address, uint256, address);
    error PaymentFailed(bytes);
    error WrongAmount(uint256, uint256);

    event TokenSold(Listing listing);
    event TokenListed(Listing listing);
    event PriceUpdated(Listing listing);
    event ListingRemoved(uint256 listingIndex);

    constructor() Ownable(msg.sender) {}

    struct Listing {
        uint256 tokenId;
        address collection;
        uint256 price;
    }

    Listing[] listedForSale;
    Listing[] offers;

    function listForSale(
        uint256 tokenId,
        address collection,
        uint256 price
    ) external {
        if (IERC721(collection).ownerOf(tokenId) != msg.sender) {
            revert NotOwnerOfToken(msg.sender, tokenId, collection);
        }

        if (!IERC721(collection).isApprovedForAll(msg.sender, address(this)) && IERC721(collection).getApproved(tokenId) != address(this)) {
            revert TokenNotApproved(msg.sender, tokenId, collection);
        }

        Listing memory listing = Listing({
            tokenId: tokenId,
            collection: collection,
            price: price
        });
        listedForSale.push(listing);
        emit TokenListed(listing);
    }

    function buyListed(uint256 listingIndex) external payable {
        Listing storage listing = listedForSale[listingIndex];

        uint256 tokenId = listing.tokenId;
        address collection = listing.collection;
        uint256 price = listing.price;

        if (!IERC721(collection).isApprovedForAll(msg.sender, address(this)) && IERC721(collection).getApproved(tokenId) != address(this)) {
            revert TokenNotApproved(msg.sender, tokenId, collection);
        }

        if (price != msg.value) {
            revert WrongAmount(price, msg.value);
        }

        address seller = IERC721(collection).ownerOf(tokenId);

        (bool sent, bytes memory data) = seller.call{value: msg.value}("");
        if (!sent) {
            revert PaymentFailed(data);
        }

        // Remove listing from array by overwriting the index with the last element, then popping.
        listedForSale[listingIndex] = listedForSale[listedForSale.length - 1];
        listedForSale.pop();

        IERC721(collection).transferFrom(seller, msg.sender, tokenId);
        emit TokenSold(listing);
    }

    function updateListed(uint256 listingIndex, uint256 newPrice) external {
        Listing storage listing = listedForSale[listingIndex];

        uint256 tokenId = listing.tokenId;
        address collection = listing.collection;

        if (IERC721(collection).ownerOf(tokenId) != msg.sender) {
            revert NotOwnerOfToken(msg.sender, tokenId, collection);
        }

        listing.price = newPrice;
        emit PriceUpdated(listing);
    }

    function removeListed(uint256 listingIndex) external {
        Listing storage listing = listedForSale[listingIndex];

        uint256 tokenId = listing.tokenId;
        address collection = listing.collection;

        if (IERC721(collection).ownerOf(tokenId) != msg.sender) {
            revert NotOwnerOfToken(msg.sender, tokenId, collection);
        }

        listedForSale[listingIndex] = listedForSale[listedForSale.length - 1];
        listedForSale.pop();
        emit ListingRemoved(listingIndex);
    }

    function getListed() external view returns (Listing[] memory) {
        return listedForSale;
    }

    function makeOffer(uint256 tokenId, address collection) external payable {}

    function acceptOffer(uint256 tokenId, address collection) external {}
}
