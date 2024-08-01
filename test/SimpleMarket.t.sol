// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../src/SimpleMarket.sol";
import "../src/TokenFlow.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract SimpleMarketTest is Test {
    address constant admin = address(uint160(uint256(1)));
    address constant customer = address(uint160(uint256(2)));
    uint256 constant tokenId = 0;
    uint256 constant tokenIdForSale = 1;

    TokenFlow tokenFlow;
    SimpleMarket simpleMarket;

    /*
        Set up: mint two tokens for $admin. Approve and list for sale the second token.
    */
    function setUp() public {
        vm.startPrank(admin);
        tokenFlow = new TokenFlow();
        tokenFlow.safeMint(admin, tokenId, "");
        tokenFlow.safeMint(admin, tokenIdForSale, "");

        simpleMarket = new SimpleMarket();

        tokenFlow.approve(address(simpleMarket), tokenIdForSale);
        simpleMarket.listForSale(tokenIdForSale, address(tokenFlow), 1 ether);
        vm.stopPrank();
    }

    function testListForSale() public {
        vm.startPrank(admin);
        SimpleMarket.Listing memory tokenListed = SimpleMarket.Listing({
            tokenId: tokenId,
            collection: address(tokenFlow),
            price: 1 ether
        });

        tokenFlow.approve(address(simpleMarket), tokenId);

        vm.expectEmit(address(simpleMarket));
        emit SimpleMarket.TokenListed(tokenListed);
        simpleMarket.listForSale(tokenId, address(tokenFlow), 1 ether);
        SimpleMarket.Listing[] memory listedForSale = simpleMarket.getListed();

        assertEq(listedForSale[1].tokenId, tokenListed.tokenId);
        assertEq(listedForSale[1].collection, tokenListed.collection);
        assertEq(listedForSale[1].price, tokenListed.price);

        vm.stopPrank();
    }

    function testBuyListed() public {
        vm.deal(customer, 2 ether);
        vm.startPrank(customer);
        simpleMarket.buyListed{value: 1 ether}(0);

        assertEq(tokenFlow.ownerOf(tokenIdForSale), customer);
        vm.stopPrank();
    }
}
