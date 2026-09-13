// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {EvmV1Decoder} from "@gluwa/asc-contracts/contracts/common/EvmV1Decoder.sol";
import {
    INativeQueryVerifier,
    NativeQueryVerifierLib
} from "@gluwa/asc-contracts/contracts/write-ability/common/INativeQueryVerifier.sol";

contract BoundsSettlement {
    uint64 public constant ETHEREUM_SEPOLIA_CHAIN_KEY = 1;
    uint256 public constant CREDITCOIN_TESTNET_CHAIN_ID = 102031;
    uint16 public constant BPS = 10_000;
    int16 public constant MINIMUM_ALLOWED_TEMPERATURE = 200;
    int16 public constant MAXIMUM_ALLOWED_TEMPERATURE = 800;

    bytes32 public constant TELEMETRY_EVENT_SIGNATURE =
        keccak256("TelemetryCommitted(bytes32,address,uint64,int16,int16,uint32,uint64,bytes32)");

    address public immutable sourceTelemetryContract;
    INativeQueryVerifier public immutable verifier;

    enum Status {
        None,
        Funded,
        Compliant,
        Breached
    }

    struct Shipment {
        address buyer;
        address carrier;
        uint128 amount;
        uint16 breachPenaltyBps;
        Status status;
        address sensor;
        uint64 telemetryNonce;
        int16 minimumTemperature;
        int16 maximumTemperature;
        uint32 outOfRangeSeconds;
        uint64 recordedAt;
        bytes32 telemetryHash;
        bytes32 queryId;
    }

    mapping(bytes32 shipmentId => Shipment shipment) public shipments;
    mapping(bytes32 queryId => bool processed) public processedQueries;
    mapping(address account => uint256 amount) public withdrawable;

    error WrongDestinationChain(uint256 actualChainId);
    error WrongSourceChain(uint64 chainKey);
    error InvalidAddress();
    error InvalidShipmentId();
    error InvalidAmount();
    error InvalidPenalty();
    error ShipmentAlreadyExists(bytes32 shipmentId);
    error ShipmentNotFunded(bytes32 shipmentId);
    error QueryAlreadyProcessed(bytes32 queryId);
    error ProofVerificationFailed();
    error FailedSourceTransaction();
    error TelemetryEventNotFound();
    error InvalidTelemetryEvent();
    error NothingToWithdraw();
    error TransferFailed();

    event ShipmentFunded(
        bytes32 indexed shipmentId,
        address indexed buyer,
        address indexed carrier,
        uint256 amount,
        uint16 breachPenaltyBps
    );

    event ShipmentSettled(
        bytes32 indexed shipmentId,
        Status indexed status,
        bytes32 indexed queryId,
        address sensor,
        uint64 telemetryNonce,
        int16 minimumTemperature,
        int16 maximumTemperature,
        uint32 outOfRangeSeconds,
        uint256 carrierCredit,
        uint256 buyerRefund
    );

    event Withdrawal(address indexed account, uint256 amount);

    constructor(address sourceTelemetryContract_) {
        if (sourceTelemetryContract_ == address(0)) revert InvalidAddress();

        sourceTelemetryContract = sourceTelemetryContract_;
        verifier = NativeQueryVerifierLib.getVerifier();
    }

    function fundShipment(bytes32 shipmentId, address carrier, uint16 breachPenaltyBps) external payable {
        if (shipmentId == bytes32(0)) revert InvalidShipmentId();
        if (carrier == address(0) || carrier == msg.sender) {
            revert InvalidAddress();
        }
        if (msg.value == 0 || msg.value > type(uint128).max) {
            revert InvalidAmount();
        }
        if (breachPenaltyBps > BPS) revert InvalidPenalty();
        if (shipments[shipmentId].status != Status.None) {
            revert ShipmentAlreadyExists(shipmentId);
        }

        shipments[shipmentId] = Shipment({
            buyer: msg.sender,
            carrier: carrier,
            amount: uint128(msg.value),
            breachPenaltyBps: breachPenaltyBps,
            status: Status.Funded,
            sensor: address(0),
            telemetryNonce: 0,
            minimumTemperature: 0,
            maximumTemperature: 0,
            outOfRangeSeconds: 0,
            recordedAt: 0,
            telemetryHash: bytes32(0),
            queryId: bytes32(0)
        });

        emit ShipmentFunded(shipmentId, msg.sender, carrier, msg.value, breachPenaltyBps);
    }

    function settleWithAttestcoin(
        uint64 chainKey,
        uint64 blockHeight,
        bytes calldata encodedTransaction,
        bytes32 merkleRoot,
        INativeQueryVerifier.MerkleProofEntry[] calldata siblings,
        bytes32 lowerEndpointDigest,
        bytes32[] calldata continuityRoots
    ) external returns (bool) {
        if (block.chainid != CREDITCOIN_TESTNET_CHAIN_ID) {
            revert WrongDestinationChain(block.chainid);
        }
        if (chainKey != ETHEREUM_SEPOLIA_CHAIN_KEY) {
            revert WrongSourceChain(chainKey);
        }

        INativeQueryVerifier.MerkleProof memory merkleProof =
            INativeQueryVerifier.MerkleProof({root: merkleRoot, siblings: siblings});

        uint64 transactionIndex = verifier.calculateTxIndex(merkleProof);
        bytes32 queryId = keccak256(abi.encodePacked(chainKey, blockHeight, transactionIndex));

        if (processedQueries[queryId]) {
            revert QueryAlreadyProcessed(queryId);
        }

        INativeQueryVerifier.ContinuityProof memory continuityProof =
            INativeQueryVerifier.ContinuityProof({lowerEndpointDigest: lowerEndpointDigest, roots: continuityRoots});

        bool verified = verifier.verifyAndEmit(chainKey, blockHeight, encodedTransaction, merkleProof, continuityProof);
        if (!verified) revert ProofVerificationFailed();

        (
            bytes32 shipmentId,
            address sensor,
            uint64 telemetryNonce,
            int16 minimumTemperature,
            int16 maximumTemperature,
            uint32 outOfRangeSeconds,
            uint64 recordedAt,
            bytes32 telemetryHash
        ) = _decodeTelemetry(encodedTransaction);

        Shipment storage shipment = shipments[shipmentId];
        if (shipment.status != Status.Funded) {
            revert ShipmentNotFunded(shipmentId);
        }

        processedQueries[queryId] = true;

        bool compliant = minimumTemperature >= MINIMUM_ALLOWED_TEMPERATURE
            && maximumTemperature <= MAXIMUM_ALLOWED_TEMPERATURE && outOfRangeSeconds == 0;

        uint256 buyerRefund;
        uint256 carrierCredit = shipment.amount;

        if (compliant) {
            shipment.status = Status.Compliant;
        } else {
            shipment.status = Status.Breached;
            buyerRefund = (uint256(shipment.amount) * shipment.breachPenaltyBps) / BPS;
            carrierCredit -= buyerRefund;
            withdrawable[shipment.buyer] += buyerRefund;
        }

        withdrawable[shipment.carrier] += carrierCredit;

        shipment.sensor = sensor;
        shipment.telemetryNonce = telemetryNonce;
        shipment.minimumTemperature = minimumTemperature;
        shipment.maximumTemperature = maximumTemperature;
        shipment.outOfRangeSeconds = outOfRangeSeconds;
        shipment.recordedAt = recordedAt;
        shipment.telemetryHash = telemetryHash;
        shipment.queryId = queryId;

        emit ShipmentSettled(
            shipmentId,
            shipment.status,
            queryId,
            sensor,
            telemetryNonce,
            minimumTemperature,
            maximumTemperature,
            outOfRangeSeconds,
            carrierCredit,
            buyerRefund
        );

        return true;
    }

    function withdraw() external {
        uint256 amount = withdrawable[msg.sender];
        if (amount == 0) revert NothingToWithdraw();

        withdrawable[msg.sender] = 0;

        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();

        emit Withdrawal(msg.sender, amount);
    }

    function _decodeTelemetry(bytes memory encodedTransaction)
        internal
        view
        returns (
            bytes32 shipmentId,
            address sensor,
            uint64 telemetryNonce,
            int16 minimumTemperature,
            int16 maximumTemperature,
            uint32 outOfRangeSeconds,
            uint64 recordedAt,
            bytes32 telemetryHash
        )
    {
        uint8 transactionType = EvmV1Decoder.getTransactionType(encodedTransaction);
        if (!EvmV1Decoder.isValidTransactionType(transactionType)) {
            revert InvalidTelemetryEvent();
        }

        EvmV1Decoder.ReceiptFields memory receipt = EvmV1Decoder.decodeReceiptFields(encodedTransaction);
        if (receipt.receiptStatus != 1) revert FailedSourceTransaction();

        EvmV1Decoder.LogEntry[] memory telemetryLogs =
            EvmV1Decoder.getLogsByEventSignature(receipt, TELEMETRY_EVENT_SIGNATURE);

        for (uint256 i; i < telemetryLogs.length; ++i) {
            EvmV1Decoder.LogEntry memory telemetryLog = telemetryLogs[i];

            if (telemetryLog.address_ != sourceTelemetryContract) continue;
            if (telemetryLog.topics.length != 4 || telemetryLog.data.length != 160) {
                revert InvalidTelemetryEvent();
            }

            shipmentId = telemetryLog.topics[1];
            sensor = address(uint160(uint256(telemetryLog.topics[2])));
            telemetryNonce = uint64(uint256(telemetryLog.topics[3]));

            (minimumTemperature, maximumTemperature, outOfRangeSeconds, recordedAt, telemetryHash) =
                abi.decode(telemetryLog.data, (int16, int16, uint32, uint64, bytes32));

            return (
                shipmentId,
                sensor,
                telemetryNonce,
                minimumTemperature,
                maximumTemperature,
                outOfRangeSeconds,
                recordedAt,
                telemetryHash
            );
        }

        revert TelemetryEventNotFound();
    }
}
