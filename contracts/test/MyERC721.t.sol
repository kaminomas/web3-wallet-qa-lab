// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {MyERC721} from "../src/MyERC721.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MyERC721Test is Test {
    MyERC721 internal nft;

    address internal owner = address(0xA11CE);
    address internal alice = address(0xA1);
    address internal bob = address(0xB0B);

    function setUp() public {
        nft = new MyERC721("MyNFT", "MNFT", "ipfs://base/", owner);
    }

    // ---------- basics ----------

    function test_Metadata() public view {
        assertEq(nft.name(), "MyNFT");
        assertEq(nft.symbol(), "MNFT");
        assertEq(nft.owner(), owner);
        assertEq(nft.totalSupply(), 0);
    }

    function test_SupportsInterface() public view {
        // ERC-165
        assertTrue(nft.supportsInterface(0x01ffc9a7));
        // ERC-721
        assertTrue(nft.supportsInterface(0x80ac58cd));
        // ERC-721 Metadata
        assertTrue(nft.supportsInterface(0x5b5e139f));
        // ERC-721 Enumerable
        assertTrue(nft.supportsInterface(0x780e9d63));
    }

    // ---------- mint ----------

    function test_OwnerCanMint() public {
        vm.prank(owner);
        uint256 id = nft.mint(alice);
        assertEq(id, 0);
        assertEq(nft.balanceOf(alice), 1);
        assertEq(nft.ownerOf(0), alice);
        assertEq(nft.totalSupply(), 1);
    }

    function test_NonOwnerCannotMint() public {
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice)
        );
        vm.prank(alice);
        nft.mint(alice);
    }

    function test_TokenURI() public {
        vm.prank(owner);
        nft.mint(alice);
        assertEq(nft.tokenURI(0), "ipfs://base/0");
    }

    function test_SetBaseURI() public {
        vm.prank(owner);
        nft.mint(alice);

        vm.prank(owner);
        nft.setBaseURI("https://new.example/");
        assertEq(nft.tokenURI(0), "https://new.example/0");
    }

    // ---------- transfer / approval ----------

    function test_Transfer() public {
        vm.prank(owner);
        nft.mint(alice);

        vm.prank(alice);
        nft.transferFrom(alice, bob, 0);

        assertEq(nft.ownerOf(0), bob);
        assertEq(nft.balanceOf(alice), 0);
        assertEq(nft.balanceOf(bob), 1);
    }

    function test_ApproveThenTransferFrom() public {
        vm.prank(owner);
        nft.mint(alice);

        vm.prank(alice);
        nft.approve(bob, 0);
        assertEq(nft.getApproved(0), bob);

        vm.prank(bob);
        nft.transferFrom(alice, bob, 0);
        assertEq(nft.ownerOf(0), bob);
    }

    function test_UnauthorizedTransferReverts() public {
        vm.prank(owner);
        nft.mint(alice);

        vm.expectRevert(
            abi.encodeWithSelector(IERC721Errors.ERC721InsufficientApproval.selector, bob, 0)
        );
        vm.prank(bob);
        nft.transferFrom(alice, bob, 0);
    }

    // ---------- enumerable ----------

    function test_EnumerableTracksTokens() public {
        vm.startPrank(owner);
        nft.mint(alice);
        nft.mint(alice);
        nft.mint(bob);
        vm.stopPrank();

        assertEq(nft.totalSupply(), 3);
        assertEq(nft.tokenByIndex(0), 0);
        assertEq(nft.tokenByIndex(1), 1);
        assertEq(nft.tokenByIndex(2), 2);

        assertEq(nft.tokenOfOwnerByIndex(alice, 0), 0);
        assertEq(nft.tokenOfOwnerByIndex(alice, 1), 1);
        assertEq(nft.tokenOfOwnerByIndex(bob, 0), 2);
    }

    // ---------- fuzz ----------

    function testFuzz_MintToMany(uint8 count) public {
        vm.assume(count > 0 && count <= 50);

        vm.startPrank(owner);
        for (uint256 i = 0; i < count; i++) {
            nft.mint(alice);
        }
        vm.stopPrank();

        assertEq(nft.balanceOf(alice), count);
        assertEq(nft.totalSupply(), count);
    }
}
