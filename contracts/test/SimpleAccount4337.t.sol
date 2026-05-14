// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {EntryPoint} from "@account-abstraction/contracts/core/EntryPoint.sol";
import {SimpleAccount} from "@account-abstraction/contracts/samples/SimpleAccount.sol";
import {SimpleAccountFactory} from "@account-abstraction/contracts/samples/SimpleAccountFactory.sol";
import {IEntryPoint} from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {PackedUserOperation} from "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/// @notice ERC-4337 v0.7 demo: deploy EntryPoint + SimpleAccountFactory, create an account,
///         build a PackedUserOperation, sign with owner EOA, submit via handleOps,
///         and verify the on-chain effect.
contract SimpleAccount4337Test is Test {
    EntryPoint internal entryPoint;
    SimpleAccountFactory internal factory;

    address internal owner;
    uint256 internal ownerPk;
    address internal beneficiary = address(0xBEEF);
    address internal recipient = address(0xCAFE);

    function setUp() public {
        (owner, ownerPk) = makeAddrAndKey("owner");

        entryPoint = new EntryPoint();
        factory = new SimpleAccountFactory(entryPoint);
    }

    // ---------- factory creates a counterfactual account ----------

    function test_FactoryReturnsDeterministicAddress() public {
        uint256 salt = 0;
        address predicted = factory.getAddress(owner, salt);
        SimpleAccount account = factory.createAccount(owner, salt);
        assertEq(address(account), predicted);
        assertEq(account.owner(), owner);
        assertEq(address(account.entryPoint()), address(entryPoint));
    }

    function test_CreateAccountIsIdempotent() public {
        uint256 salt = 1;
        SimpleAccount a = factory.createAccount(owner, salt);
        SimpleAccount b = factory.createAccount(owner, salt);
        assertEq(address(a), address(b));
    }

    // ---------- full UserOperation flow ----------

    function test_UserOperation_TransfersEthFromAccount() public {
        SimpleAccount account = factory.createAccount(owner, 0);
        vm.deal(address(account), 2 ether);

        PackedUserOperation memory userOp = _buildExecuteUserOp({
            sender: address(account),
            target: recipient,
            value: 1 ether,
            data: ""
        });
        userOp.signature = _signUserOp(userOp);

        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = userOp;

        uint256 beneficiaryBalanceBefore = beneficiary.balance;
        entryPoint.handleOps(ops, payable(beneficiary));

        assertEq(recipient.balance, 1 ether, "recipient should have received 1 ether");
        assertLt(address(account).balance, 1 ether, "account balance reduced by transfer + gas");
        assertGt(beneficiary.balance, beneficiaryBalanceBefore, "bundler is reimbursed");
    }

    function test_UserOperation_InvalidSignatureReverts() public {
        SimpleAccount account = factory.createAccount(owner, 0);
        vm.deal(address(account), 2 ether);

        PackedUserOperation memory userOp = _buildExecuteUserOp({
            sender: address(account),
            target: recipient,
            value: 1 ether,
            data: ""
        });
        // Sign with a different key
        (, uint256 attackerPk) = makeAddrAndKey("attacker");
        bytes32 hash = entryPoint.getUserOpHash(userOp);
        bytes32 ethSignedHash = MessageHashUtils.toEthSignedMessageHash(hash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(attackerPk, ethSignedHash);
        userOp.signature = abi.encodePacked(r, s, v);

        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = userOp;

        vm.expectRevert();
        entryPoint.handleOps(ops, payable(beneficiary));
    }

    function test_UserOperation_NonceIncrementsAfterExecution() public {
        SimpleAccount account = factory.createAccount(owner, 0);
        vm.deal(address(account), 3 ether);

        assertEq(entryPoint.getNonce(address(account), 0), 0);

        PackedUserOperation memory userOp = _buildExecuteUserOp({
            sender: address(account),
            target: recipient,
            value: 0.5 ether,
            data: ""
        });
        userOp.signature = _signUserOp(userOp);

        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = userOp;
        entryPoint.handleOps(ops, payable(beneficiary));

        assertEq(entryPoint.getNonce(address(account), 0), 1, "nonce should increment");
    }

    // ---------- helpers ----------

    function _buildExecuteUserOp(address sender, address target, uint256 value, bytes memory data)
        internal
        view
        returns (PackedUserOperation memory)
    {
        bytes memory callData = abi.encodeWithSelector(SimpleAccount.execute.selector, target, value, data);

        // v0.7 packs: accountGasLimits = verificationGasLimit (high 16B) | callGasLimit (low 16B)
        bytes32 accountGasLimits = bytes32((uint256(500_000) << 128) | uint256(200_000));
        // gasFees = maxPriorityFeePerGas (high 16B) | maxFeePerGas (low 16B)
        bytes32 gasFees = bytes32((uint256(1 gwei) << 128) | uint256(100 gwei));

        return PackedUserOperation({
            sender: sender,
            nonce: entryPoint.getNonce(sender, 0),
            initCode: "",
            callData: callData,
            accountGasLimits: accountGasLimits,
            preVerificationGas: 50_000,
            gasFees: gasFees,
            paymasterAndData: "",
            signature: ""
        });
    }

    function _signUserOp(PackedUserOperation memory userOp) internal view returns (bytes memory) {
        bytes32 hash = entryPoint.getUserOpHash(userOp);
        bytes32 ethSignedHash = MessageHashUtils.toEthSignedMessageHash(hash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPk, ethSignedHash);
        return abi.encodePacked(r, s, v);
    }
}
