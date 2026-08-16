// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AUPRegistry.sol";
import "./AUPReputation.sol";

/**
 * @title AUPGuard
 * @notice Economic safety layer / spending guard for Agents Utility Persistent (AUP)
 */
contract AUPGuard {
    AUPRegistry public immutable registry;
    AUPReputation public immutable reputation;

    struct GuardConfig {
        uint256 maxBudget;
        uint256 maxCostPerTask;
        uint256 minAupScore;
        bool enabled;
    }

    mapping(address => GuardConfig) public userGuards;
    mapping(address => uint256) public spentBudget;

    event GuardConfigured(
        address indexed user,
        uint256 maxBudget,
        uint256 maxCostPerTask,
        uint256 minAupScore
    );

    event GuardDisabled(address indexed user);
    event ExecutionChecked(
        address indexed user,
        uint256 indexed agentId,
        uint256 estimatedCost,
        bool allowed,
        string reason
    );

    constructor(address registryAddress, address reputationAddress) {
        require(registryAddress != address(0) && reputationAddress != address(0), "Invalid addresses");
        registry = AUPRegistry(registryAddress);
        reputation = AUPReputation(reputationAddress);
    }

    function configureGuard(
        uint256 maxBudget,
        uint256 maxCostPerTask,
        uint256 minAupScore
    ) external {
        require(minAupScore <= 100, "minAupScore > 100");
        userGuards[msg.sender] = GuardConfig({
            maxBudget: maxBudget,
            maxCostPerTask: maxCostPerTask,
            minAupScore: minAupScore,
            enabled: true
        });
        spentBudget[msg.sender] = 0;

        emit GuardConfigured(msg.sender, maxBudget, maxCostPerTask, minAupScore);
    }

    function disableGuard() external {
        userGuards[msg.sender].enabled = false;
        emit GuardDisabled(msg.sender);
    }

    function canExecute(
        address user,
        uint256 agentId,
        uint256 estimatedCost
    ) public view returns (bool allowed, string memory reason) {
        GuardConfig memory config = userGuards[user];

        if (!config.enabled) {
            return (true, "Guard not enabled");
        }

        if (!registry.isActiveAgent(agentId)) {
            return (false, "Agent not active or does not exist");
        }

        uint256 score = reputation.getAupScore(agentId);
        if (score < config.minAupScore) {
            return (false, "AUP Score below minimum");
        }

        if (estimatedCost > config.maxCostPerTask) {
            return (false, "Cost exceeds maxCostPerTask");
        }

        uint256 alreadySpent = spentBudget[user];
        if (alreadySpent + estimatedCost > config.maxBudget) {
            return (false, "Would exceed maxBudget");
        }

        return (true, "Allowed");
    }

    function checkAndLog(
        uint256 agentId,
        uint256 estimatedCost
    ) external returns (bool allowed, string memory reason) {
        (allowed, reason) = canExecute(msg.sender, agentId, estimatedCost);
        emit ExecutionChecked(msg.sender, agentId, estimatedCost, allowed, reason);
    }

    function recordSpend(uint256 cost) external {
        GuardConfig memory config = userGuards[msg.sender];
        require(config.enabled, "Guard not enabled");
        spentBudget[msg.sender] += cost;
    }

    function getUserGuard(address user) external view returns (GuardConfig memory) {
        return userGuards[user];
    }

    function remainingBudget(address user) external view returns (uint256) {
        GuardConfig memory config = userGuards[user];
        if (!config.enabled) return type(uint256).max;
        uint256 spent = spentBudget[user];
        return spent >= config.maxBudget ? 0 : config.maxBudget - spent;
    }
}