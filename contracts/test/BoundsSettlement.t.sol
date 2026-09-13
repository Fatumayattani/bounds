// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {BoundsSettlement} from "../src/BoundsSettlement.sol";
import {EvmV1Decoder} from "@gluwa/asc-contracts/contracts/common/EvmV1Decoder.sol";
import {INativeQueryVerifier} from "@gluwa/asc-contracts/contracts/write-ability/common/INativeQueryVerifier.sol";

contract MockNativeQueryVerifier is INativeQueryVerifier {
    function verifyAndEmit(uint64, uint64, bytes calldata, MerkleProof calldata, ContinuityProof calldata)
        external
        pure
        returns (bool)
    {
        return true;
    }

    function verifyAndEmit(
        uint64,
        uint64[] calldata,
        bytes[] calldata,
        MerkleProof[] calldata,
        ContinuityProof calldata
    ) external pure returns (bool) {
        return true;
    }

    function verify(uint64, uint64, bytes calldata, MerkleProof calldata, ContinuityProof calldata)
        external
        pure
        returns (bool)
    {
        return true;
    }

    function verify(uint64, uint64[] calldata, bytes[] calldata, MerkleProof[] calldata, ContinuityProof calldata)
        external
        pure
        returns (bool)
    {
        return true;
    }

    function calculateTxIndex(MerkleProof calldata) external pure returns (uint64) {
        return 7;
    }
}

contract BoundsSettlementTest is Test {
    address internal constant BLOCK_PROVER = 0x0000000000000000000000000000000000000FD2;
    address internal constant SOURCE_TELEMETRY = 0x4b403e46800A485fdE2a0be2228228f78f20C7D4;
    address internal constant SENSOR = 0xB51A5de45176aE2bC606d837fb9Dd3aeD5647101;

    address internal buyer = makeAddr("buyer");
    address internal carrier = makeAddr("carrier");

    bytes32 internal constant SAFE_SHIPMENT = keccak256("BND-001");
    bytes32 internal constant BREACH_SHIPMENT = keccak256("BND-BREACH-001");

    BoundsSettlement internal settlement;

    function setUp() public {
        vm.chainId(102031);

        MockNativeQueryVerifier mockVerifier = new MockNativeQueryVerifier();
        vm.etch(BLOCK_PROVER, address(mockVerifier).code);

        settlement = new BoundsSettlement(SOURCE_TELEMETRY);
        vm.deal(buyer, 10 ether);
    }

    function _fund(bytes32 shipmentId, uint16 penaltyBps) internal {
        vm.prank(buyer);
        settlement.fundShipment{value: 1 ether}(shipmentId, carrier, penaltyBps);
    }

    function _proofParts()
        internal
        pure
        returns (
            bytes32 merkleRoot,
            INativeQueryVerifier.MerkleProofEntry[] memory siblings,
            bytes32 lowerEndpointDigest,
            bytes32[] memory continuityRoots
        )
    {
        merkleRoot = keccak256("merkle-root");
        siblings = new INativeQueryVerifier.MerkleProofEntry[](0);
        lowerEndpointDigest = keccak256("lower-endpoint");
        continuityRoots = new bytes32[](0);
    }

    function _encodedTelemetry(
        address emitter,
        bytes32 shipmentId,
        int16 minimumTemperature,
        int16 maximumTemperature,
        uint32 outOfRangeSeconds
    ) internal pure returns (bytes memory) {
        bytes32[] memory topics = new bytes32[](4);
        topics[0] = keccak256("TelemetryCommitted(bytes32,address,uint64,int16,int16,uint32,uint64,bytes32)");
        topics[1] = shipmentId;
        topics[2] = bytes32(uint256(uint160(SENSOR)));
        topics[3] = bytes32(uint256(1));

        EvmV1Decoder.LogEntryTuple[] memory logs = new EvmV1Decoder.LogEntryTuple[](1);
        logs[0] = EvmV1Decoder.LogEntryTuple({
            address_: emitter,
            topics: topics,
            data: abi.encode(
                minimumTemperature,
                maximumTemperature,
                outOfRangeSeconds,
                uint64(1_789_315_446),
                keccak256("telemetry-payload")
            )
        });

        bytes[] memory chunks = new bytes[](3);
        chunks[0] = abi.encode(uint64(1), uint64(200_000), SENSOR, false, SOURCE_TELEMETRY, uint256(0), bytes(""));

        EvmV1Decoder.AccessListEntryBytes32[] memory accessList = new EvmV1Decoder.AccessListEntryBytes32[](0);
        chunks[1] = abi.encode(
            uint64(11155111),
            uint128(1 gwei),
            uint128(2 gwei),
            accessList,
            uint8(0),
            bytes32(uint256(1)),
            bytes32(uint256(2))
        );

        chunks[2] = abi.encode(uint8(1), uint64(100_000), logs, bytes(""));

        return abi.encode(uint8(2), chunks);
    }

    function _settle(
        bytes32 shipmentId,
        int16 minimumTemperature,
        int16 maximumTemperature,
        uint32 outOfRangeSeconds,
        uint64 blockHeight,
        address emitter
    ) internal {
        (
            bytes32 merkleRoot,
            INativeQueryVerifier.MerkleProofEntry[] memory siblings,
            bytes32 lowerEndpointDigest,
            bytes32[] memory continuityRoots
        ) = _proofParts();

        settlement.settleWithAttestcoin(
            1,
            blockHeight,
            _encodedTelemetry(emitter, shipmentId, minimumTemperature, maximumTemperature, outOfRangeSeconds),
            merkleRoot,
            siblings,
            lowerEndpointDigest,
            continuityRoots
        );
    }

    function testFundsShipmentEscrow() public {
        _fund(SAFE_SHIPMENT, 2_500);

        (
            address storedBuyer,
            address storedCarrier,
            uint128 amount,
            uint16 penaltyBps,
            BoundsSettlement.Status status,,,,,,,,
        ) = settlement.shipments(SAFE_SHIPMENT);

        assertEq(storedBuyer, buyer);
        assertEq(storedCarrier, carrier);
        assertEq(amount, 1 ether);
        assertEq(penaltyBps, 2_500);
        assertEq(uint8(status), uint8(BoundsSettlement.Status.Funded));
    }

    function testAttestcoinProofReleasesCompliantShipment() public {
        _fund(SAFE_SHIPMENT, 2_500);

        _settle(SAFE_SHIPMENT, 400, 450, 0, 11_696_942, SOURCE_TELEMETRY);

        assertEq(settlement.withdrawable(carrier), 1 ether);
        assertEq(settlement.withdrawable(buyer), 0);

        (,,,, BoundsSettlement.Status status,,,,,,,,) = settlement.shipments(SAFE_SHIPMENT);
        assertEq(uint8(status), uint8(BoundsSettlement.Status.Compliant));
    }

    function testAttestcoinProofAppliesBreachPenalty() public {
        _fund(BREACH_SHIPMENT, 2_500);

        _settle(BREACH_SHIPMENT, 420, 1_010, 120, 11_696_964, SOURCE_TELEMETRY);

        assertEq(settlement.withdrawable(carrier), 0.75 ether);
        assertEq(settlement.withdrawable(buyer), 0.25 ether);

        (,,,, BoundsSettlement.Status status,,,,,,,,) = settlement.shipments(BREACH_SHIPMENT);
        assertEq(uint8(status), uint8(BoundsSettlement.Status.Breached));
    }

    function testRejectsWrongSourceChain() public {
        _fund(SAFE_SHIPMENT, 2_500);

        (
            bytes32 merkleRoot,
            INativeQueryVerifier.MerkleProofEntry[] memory siblings,
            bytes32 lowerEndpointDigest,
            bytes32[] memory continuityRoots
        ) = _proofParts();

        vm.expectRevert(abi.encodeWithSelector(BoundsSettlement.WrongSourceChain.selector, uint64(3)));
        settlement.settleWithAttestcoin(
            3,
            11_696_942,
            _encodedTelemetry(SOURCE_TELEMETRY, SAFE_SHIPMENT, 400, 450, 0),
            merkleRoot,
            siblings,
            lowerEndpointDigest,
            continuityRoots
        );
    }

    function testRejectsWrongDestinationChain() public {
        _fund(SAFE_SHIPMENT, 2_500);
        vm.chainId(1);

        (
            bytes32 merkleRoot,
            INativeQueryVerifier.MerkleProofEntry[] memory siblings,
            bytes32 lowerEndpointDigest,
            bytes32[] memory continuityRoots
        ) = _proofParts();

        vm.expectRevert(abi.encodeWithSelector(BoundsSettlement.WrongDestinationChain.selector, uint256(1)));
        settlement.settleWithAttestcoin(
            1,
            11_696_942,
            _encodedTelemetry(SOURCE_TELEMETRY, SAFE_SHIPMENT, 400, 450, 0),
            merkleRoot,
            siblings,
            lowerEndpointDigest,
            continuityRoots
        );
    }

    function testRejectsEventFromUnregisteredContract() public {
        _fund(SAFE_SHIPMENT, 2_500);

        vm.expectRevert(BoundsSettlement.TelemetryEventNotFound.selector);
        _settle(SAFE_SHIPMENT, 400, 450, 0, 11_696_942, makeAddr("impostor"));
    }

    function testRejectsProofReplay() public {
        _fund(SAFE_SHIPMENT, 2_500);
        _settle(SAFE_SHIPMENT, 400, 450, 0, 11_696_942, SOURCE_TELEMETRY);

        bytes32 expectedQueryId = keccak256(abi.encodePacked(uint64(1), uint64(11_696_942), uint64(7)));

        vm.expectRevert(abi.encodeWithSelector(BoundsSettlement.QueryAlreadyProcessed.selector, expectedQueryId));
        _settle(SAFE_SHIPMENT, 400, 450, 0, 11_696_942, SOURCE_TELEMETRY);
    }

    function testCreditsCanBeWithdrawn() public {
        _fund(SAFE_SHIPMENT, 2_500);
        _settle(SAFE_SHIPMENT, 400, 450, 0, 11_696_942, SOURCE_TELEMETRY);

        uint256 beforeBalance = carrier.balance;

        vm.prank(carrier);
        settlement.withdraw();

        assertEq(carrier.balance, beforeBalance + 1 ether);
        assertEq(settlement.withdrawable(carrier), 0);
    }
}
