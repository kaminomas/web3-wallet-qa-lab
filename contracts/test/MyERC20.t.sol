// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {MyERC20} from "../src/MyERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract MyERC20Test is Test {
    MyERC20 internal token;

    address internal owner = address(0xA11CE);
    address internal alice;
    uint256 internal alicePk;
    address internal bob = address(0xB0B);

    bytes32 internal constant PERMIT_TYPEHASH = keccak256(
        "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );

    function setUp() public {
        token = new MyERC20("MyToken", "MTK", owner);
        (alice, alicePk) = makeAddrAndKey("alice");
    }

    // ---------- basics ----------

    function test_Metadata() public view {
        assertEq(token.name(), "MyToken");
        assertEq(token.symbol(), "MTK");
        assertEq(token.decimals(), 18);
        assertEq(token.owner(), owner);
        assertEq(token.totalSupply(), 0);
    }

    function test_OwnerCanMint() public {
        vm.prank(owner);
        token.mint(alice, 1_000e18);
        assertEq(token.balanceOf(alice), 1_000e18);
        assertEq(token.totalSupply(), 1_000e18);
    }

    function test_NonOwnerCannotMint() public {
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice)
        );
        vm.prank(alice);
        token.mint(alice, 1e18);
    }

    // ---------- transfer / allowance ----------

    function test_Transfer() public {
        vm.prank(owner);
        token.mint(alice, 100e18);

        vm.prank(alice);
        assertTrue(token.transfer(bob, 40e18));

        assertEq(token.balanceOf(alice), 60e18);
        assertEq(token.balanceOf(bob), 40e18);
    }

    function test_TransferInsufficientBalanceReverts() public {
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, alice, 0, 1)
        );
        vm.prank(alice);
        token.transfer(bob, 1);
    }

    function test_TransferFromConsumesAllowance() public {
        vm.prank(owner);
        token.mint(alice, 100e18);

        vm.prank(alice);
        token.approve(bob, 50e18);
        assertEq(token.allowance(alice, bob), 50e18);

        vm.prank(bob);
        token.transferFrom(alice, bob, 30e18);

        assertEq(token.balanceOf(bob), 30e18);
        assertEq(token.allowance(alice, bob), 20e18);
    }

    // ---------- EIP-2612 permit ----------

    function test_Permit_Succeeds() public {
        uint256 value = 1_000e18;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(alice);

        bytes32 digest = _permitDigest(alice, bob, value, nonce, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, digest);

        token.permit(alice, bob, value, deadline, v, r, s);

        assertEq(token.allowance(alice, bob), value);
        assertEq(token.nonces(alice), nonce + 1);
    }

    function test_Permit_ExpiredDeadlineReverts() public {
        uint256 value = 1e18;
        uint256 deadline = block.timestamp - 1;
        uint256 nonce = token.nonces(alice);

        bytes32 digest = _permitDigest(alice, bob, value, nonce, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, digest);

        vm.expectRevert(
            abi.encodeWithSelector(ERC20Permit.ERC2612ExpiredSignature.selector, deadline)
        );
        token.permit(alice, bob, value, deadline, v, r, s);
    }

    function test_Permit_WrongSignerReverts() public {
        uint256 value = 1e18;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(alice);

        // Sign with bob's key but claim it's alice's permit
        (, uint256 bobPk) = makeAddrAndKey("bob-signer");
        bytes32 digest = _permitDigest(alice, bob, value, nonce, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bobPk, digest);

        vm.expectRevert();
        token.permit(alice, bob, value, deadline, v, r, s);
    }

    function test_Permit_ReplayReverts() public {
        uint256 value = 1e18;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(alice);

        bytes32 digest = _permitDigest(alice, bob, value, nonce, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, digest);

        token.permit(alice, bob, value, deadline, v, r, s);

        // Replay: nonce has been bumped, so the same signature is no longer valid
        vm.expectRevert();
        token.permit(alice, bob, value, deadline, v, r, s);
    }

    // ---------- fuzz ----------

    function testFuzz_MintAndTransfer(uint128 mintAmount, uint128 sendAmount) public {
        vm.assume(sendAmount <= mintAmount);

        vm.prank(owner);
        token.mint(alice, mintAmount);

        vm.prank(alice);
        token.transfer(bob, sendAmount);

        assertEq(token.balanceOf(alice), uint256(mintAmount) - sendAmount);
        assertEq(token.balanceOf(bob), sendAmount);
    }

    // ---------- helpers ----------

    function _permitDigest(
        address owner_,
        address spender,
        uint256 value,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(PERMIT_TYPEHASH, owner_, spender, value, nonce, deadline)
        );
        return MessageHashUtils.toTypedDataHash(token.DOMAIN_SEPARATOR(), structHash);
    }
}
