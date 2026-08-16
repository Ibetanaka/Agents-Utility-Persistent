// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AUPRegistry.sol";

/**
 * @title AUPReputation
 * @notice Core reputation & scoring contract for Agents Utility Persistent (AUP)
 * @dev Stores execution history, calculates Utility / Efficiency / Reliability / Reputation
 *      and final AUP Score (0-100).
 *
 * Scoring weights (from README):
 *   40% Utility
 *   30% Efficiency
 *   20% Reliability
 *   10% Reputation
 */
contract AUPReputation {
    AUPRegistry public immutable registry;

    address public owner;
    mapping(address => bool) public evaluators; // only authorized evaluators can record executions

    struct AgentStats {
        uint256 totalTasks;
        uint256 successfulTasks;
        uint256 failedTasks;
        uint256 totalCost;          // cumulative cost (in cost units, e.g. micro-USD)
        uint256 totalUtility;       // sum of utility scores submitted
        uint256 utilityScore;       // average utility (0-100)
        uint256 efficiencyScore;    // 0-100 (higher = more cost efficient)
        uint256 reliabilityScore;   // success rate * 100
        uint256 reputationScore;    // derived score (0-100)
        uint256 aupScore;           // final weighted score (0-100)
        uint256 lastUpdated;
    }

    mapping(uint256 => AgentStats) public stats;                 // agentId => stats
    mapping(bytes32 => bool) public executionRecorded;           // prevent double reporting

    // Minimum tasks before scores become meaningful (anti-sybil / cold start)
    uint256 public constant MIN_TASKS_FOR_SCORE = 3;

    event EvaluatorUpdated(address indexed evaluator, bool allowed);
    event ExecutionRecorded(
        uint256 indexed agentId,
        bytes32 indexed executionId,
        bool success,
        uint256 cost,
        uint256 utility,
        uint256 newAupScore
    );
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyEvaluator() {
        require(evaluators[msg.sender] || msg.sender == owner, "Not evaluator");
        _;
    }

    constructor(address registryAddress) {
        require(registryAddress != address(0), "Invalid registry");
        registry = AUPRegistry(registryAddress);
        owner = msg.sender;
        evaluators[msg.sender] = true;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function setEvaluator(address evaluator, bool allowed) external onlyOwner {
        evaluators[evaluator] = allowed;
        emit EvaluatorUpdated(evaluator, allowed);
    }

    /**
     * @notice Record a single agent execution result.
     * @param agentId       ID from AUPRegistry
     * @param executionId   Unique ID of this execution (hash of task+timestamp etc.) to prevent replay
     * @param success       Whether the task succeeded
     * @param cost          Cost incurred (in arbitrary units, recommend micro-USD: 1 = $0.000001)
     * @param utility       Utility score given by evaluator (0-100)
     */
    function recordExecution(
        uint256 agentId,
        bytes32 executionId,
        bool success,
        uint256 cost,
        uint256 utility
    ) external onlyEvaluator {
        require(registry.isActiveAgent(agentId), "Agent not active");
        require(!executionRecorded[executionId], "Execution already recorded");
        require(utility <= 100, "Utility > 100");

        executionRecorded[executionId] = true;

        AgentStats storage s = stats[agentId];

        s.totalTasks += 1;
        if (success) {
            s.successfulTasks += 1;
        } else {
            s.failedTasks += 1;
        }
        s.totalCost += cost;
        s.totalUtility += utility;
        s.lastUpdated = block.timestamp;

        // Recalculate scores
        _recalculate(agentId);

        emit ExecutionRecorded(agentId, executionId, suc
... 