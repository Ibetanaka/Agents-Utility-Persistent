// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AUPRegistry.sol";

/**
 * @title AUPReputation
 * @notice Core reputation & scoring contract for Agents Utility Persistent (AUP)
 */
contract AUPReputation {
    AUPRegistry public immutable registry;

    address public owner;
    mapping(address => bool) public evaluators;

    struct AgentStats {
        uint256 totalTasks;
        uint256 successfulTasks;
        uint256 failedTasks;
        uint256 totalCost;
        uint256 totalUtility;
        uint256 utilityScore;
        uint256 efficiencyScore;
        uint256 reliabilityScore;
        uint256 reputationScore;
        uint256 aupScore;
        uint256 lastUpdated;
    }

    mapping(uint256 => AgentStats) public stats;
    mapping(bytes32 => bool) public executionRecorded;

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

        _recalculate(agentId);

        emit ExecutionRecorded(agentId, executionId, success, cost, utility, s.aupScore);
    }

    function _recalculate(uint256 agentId) internal {
        AgentStats storage s = stats[agentId];

        if (s.totalTasks == 0) {
            s.utilityScore = 0;
            s.efficiencyScore = 0;
            s.reliabilityScore = 0;
            s.reputationScore = 0;
            s.aupScore = 0;
            return;
        }

        s.utilityScore = s.totalUtility / s.totalTasks;
        s.reliabilityScore = (s.successfulTasks * 100) / s.totalTasks;

        uint256 avgCost = s.totalCost / s.totalTasks;
        uint256 penalty = avgCost / 10;
        s.efficiencyScore = penalty >= 100 ? 0 : 100 - penalty;

        s.reputationScore = (s.reliabilityScore * 70 + s.utilityScore * 30) / 100;

        if (s.totalTasks < MIN_TASKS_FOR_SCORE) {
            s.aupScore = (s.utilityScore * 40 + s.efficiencyScore * 30 + s.reliabilityScore * 20 + s.reputationScore * 10) / 100;
            s.aupScore = s.aupScore * s.totalTasks / MIN_TASKS_FOR_SCORE;
        } else {
            s.aupScore = (s.utilityScore * 40 + s.efficiencyScore * 30 + s.reliabilityScore * 20 + s.reputationScore * 10) / 100;
        }
    }

    function getAupScore(uint256 agentId) external view returns (uint256) {
        return stats[agentId].aupScore;
    }

    function getAgentStats(uint256 agentId) external view returns (AgentStats memory) {
        return stats[agentId];
    }

    function getScores(uint256 agentId)
        external
        view
        returns (
            uint256 utilityScore,
            uint256 efficiencyScore,
            uint256 reliabilityScore,
            uint256 reputationScore,
            uint256 aupScore
        )
    {
        AgentStats memory s = stats[agentId];
        return (s.utilityScore, s.efficiencyScore, s.reliabilityScore, s.reputationScore, s.aupScore);
    }
}