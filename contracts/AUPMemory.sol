// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AUPMemory
 * @notice Persistent experience memory for AI agents.
 *
 * AUPMemory stores compact, verifiable memory signals from
 * previous agent executions. It does not store full conversations.
 */
contract AUPMemory {
    struct Memory {
        uint256 agentId;
        bytes32 executionId;
        bool success;
        uint256 utility;
        uint256 cost;
        uint64 timestamp;
        bytes32 reference;
    }

    address public owner;
    address public recorder;

    mapping(uint256 => Memory[]) private agentMemories;

    event MemoryRecorded(
        uint256 indexed agentId,
        bytes32 indexed executionId,
        bool success,
        uint256 utility,
        uint256 cost,
        uint64 timestamp,
        bytes32 reference
    );

    event RecorderUpdated(
        address indexed previousRecorder,
        address indexed newRecorder
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "AUPMemory: not owner");
        _;
    }

    modifier onlyRecorder() {
        require(
            msg.sender == owner || msg.sender == recorder,
            "AUPMemory: not recorder"
        );
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Set the address allowed to write agent memories.
     * @param newRecorder Address of the authorized recorder.
     */
    function setRecorder(address newRecorder) external onlyOwner {
        address previousRecorder = recorder;
        recorder = newRecorder;

        emit RecorderUpdated(previousRecorder, newRecorder);
    }

    /**
     * @notice Record a compact memory of an agent execution.
     */
    function recordMemory(
        uint256 agentId,
        bytes32 executionId,
        bool success,
        uint256 utility,
        uint256 cost,
        bytes32 reference
    ) external onlyRecorder {
        Memory memoryEntry = Memory({
            agentId: agentId,
            executionId: executionId,
            success: success,
            utility: utility,
            cost: cost,
            timestamp: uint64(block.timestamp),
            reference: reference
        });

        agentMemories[agentId].push(memoryEntry);

        emit MemoryRecorded(
            agentId,
            executionId,
            success,
            utility,
            cost,
            uint64(block.timestamp),
            reference
        );
    }

    /**
     * @notice Return the number of memories stored for an agent.
     */
    function getMemoryCount(
        uint256 agentId
    ) external view returns (uint256) {
        return agentMemories[agentId].length;
    }

    /**
     * @notice Recall a specific memory entry.
     */
    function getMemory(
        uint256 agentId,
        uint256 index
    ) external view returns (Memory memoryEntry) {
        require(
            index < agentMemories[agentId].length,
            "AUPMemory: invalid index"
        );

        return agentMemories[agentId][index];
    }

    /**
     * @notice Recall the most recent memory for an agent.
     */
    function getLatestMemory(
        uint256 agentId
    ) external view returns (Memory memoryEntry) {
        uint256 count = agentMemories[agentId].length;

        require(count > 0, "AUPMemory: no memory");

        return agentMemories[agentId][count - 1];
    }

    /**
     * @notice Recall whether an agent has previous experience.
     */
    function hasMemory(
        uint256 agentId
    ) external view returns (bool) {
        return agentMemories[agentId].length > 0;
    }

    /**
     * @notice Transfer ownership.
     */
    function transferOwnership(
        address newOwner
    ) external onlyOwner {
        require(
            newOwner != address(0),
            "AUPMemory: zero owner"
        );

        owner = newOwner;
    }
}
