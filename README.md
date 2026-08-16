# Agents Utility Persistent
The reputation and economic safety layer for AI agents.AUP measures AI agent utility, efficiency, reliability, andcost performance to help users make safer and more economicalagent execution decisions.




# AUP — Agents Utility Persistent

The reputation and economic safety layer for AI agents.

AUP measures AI agent utility, efficiency, reliability, and
cost performance to help users make safer and more economical
agent execution decisions.

## Why AUP?

AI agents can consume unpredictable resources and costs.
Users need a reliable way to evaluate an agent before execution.

AUP provides an on-chain reputation layer that turns agent
performance into a transparent AUP Score.

## Core Features

- Agent Registry
- On-chain Reputation
- Utility Score
- Cost Efficiency Score
- Reliability Score
- Agent Risk Assessment
- Spending Guard
- Verifiable Agent Performance

## AUP Score

AUP Score evaluates an agent from 0–100 based on:

- Utility
- Efficiency
- Reliability
- Reputation

## Architecture

User
 ↓
AUP Registry
 ↓
Agent Evaluation
 ↓
AUP Reputation Contract
 ↓
AUP Score
 ↓
Risk & Cost Assessment
 ↓
Spending Guard

## Smart Contracts

- AUPRegistry.sol
- AUPReputation.sol
- AUPGuard.sol

## Goal

AUP aims to become an economic reputation and safety
infrastructure for autonomous AI agents.

## Status

MVP — In Development

## License

MIT


## AUP MVP ARCHITECTURE


                    ┌──────────────────┐
                    │      USER        │
                    └────────┬─────────┘
                             │
                     Request AI Agent
                             │
                             ▼
                    ┌──────────────────┐
                    │   AUP Registry   │
                    │                  │
                    │ Agent ID         │
                    │ Agent Address    │
                    │ Category         │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │  Agent Executes  │
                    │      Task        │
                    └────────┬─────────┘
                             │
                 ┌───────────┼───────────┐
                 ▼           ▼           ▼
              Result       Cost      Feedback
                 │           │           │
                 └───────────┼───────────┘
                             ▼
                    ┌──────────────────┐
                    │ AUP Evaluator    │
                    │                  │
                    │ Utility          │
                    │ Efficiency       │
                    │ Reliability      │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │ AUP Reputation   │
                    │    Contract      │
                    └────────┬─────────┘
                             │
                             ▼
                       AUP SCORE
                         0–100
                             │
                             ▼
                    ┌──────────────────┐
                    │   AUP Guard      │
                    │                  │
                    │ Cost Limit       │
                    │ Risk Check       │
                    └────────┬─────────┘
                             │
                       ALLOW / BLOCK



VIBES STRUCTURE:

1. AUPRegistry.sol 

The first function simply registers an agent.
 Minimum data:

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AUPRegistry
 * @notice Agent registration contract for Agents Utility Persistent (AUP)
 * @dev Stores basic agent metadata for discovery and ownership tracking.
 */
contract AUPRegistry {
    struct Agent {
        uint256 agentId;
        address agentAddress;   // The on-chain or off-chain agent identifier address
        address owner;          // Who registered / owns this agent record
        string category;        // e.g. "Research", "Trading", "Coding"
        bool active;
        uint256 registeredAt;
    }

    uint256 public nextAgentId = 1;

    mapping(uint256 => Agent) public agents;
    mapping(address => uint256[]) private _ownerAgents;
    mapping(address => uint256) public agentAddressToId; // optional reverse lookup

    event AgentRegistered(
        uint256 indexed agentId,
        address indexed agentAddress,
        address indexed owner,
        string category
    );

    event AgentStatusUpdated(uint256 indexed agentId, bool active);

    /**
     * @notice Register a new agent
     * @param agentAddress Address associated with the agent (can be EOA or contract)
     * @param category Category / type of the agent
     * @return agentId The newly assigned agent ID
     */
    function registerAgent(address agentAddress, string calldata category) external returns (uint256) {
        require(agentAddress != address(0), "Invalid agent address");
        require(bytes(category).length > 0, "Category required");

        uint256 agentId = nextAgentId++;

        agents[agentId] = Agent({
            agentId: agentId,
            agentAddress: agentAddress,
            owner: msg.sender,
            category: category,
            active: true,
            registeredAt: block.timestamp
        });

        _ownerAgents[msg.sender].push(agentId);
        agentAddressToId[agentAddress] = agentId;

        emit AgentRegistered(agentId, agentAddress, msg.sender, category);
        return agentId;
    }

    /**
     * @notice Activate or deactivate an agent (only owner)
     */
    function setAgentActive(uint256 agentId, bool active) external {
        Agent storage agent = agents[agentId];
        require(agent.agentId != 0, "Agent does not exist");
        require(msg.sender == agent.owner, "Not agent owner");
        agent.active = active;
        emit AgentStatusUpdated(agentId, active);
    }

    /**
     * @notice Get all agent IDs owned by an address
     */
    function getAgentsByOwner(address owner) external view returns (uint256[] memory) {
        return _ownerAgents[owner];
    }

    /**
     * @notice Check if an agent exists and is active
     */
    function isActiveAgent(uint256 agentId) external view returns (bool) {
        Agent memory agent = agents[agentId];
        return agent.agentId != 0 && agent.active;
    }

    /**
     * @notice Get full agent data
     */
    function getAgent(uint256 agentId) external view returns (Agent memory) {
        return agents[agentId];
    }
}



agentId
agentAddress
owner
category
active
registeredAt

ex: Agent #001
Research Agent
Owner: 0x...
Status: Active


2. AUPReputation.sol

This is the core of the AUP. The contract stores statistics:

totalTasks
successfulTasks
failedTasks
totalCost
utilityScore
efficiencyScore
reliabilityScore
reputationScore
aupScore

3. AUP SCORE:

40% Utility
30% Efficiency
20% Reliability
10% Reputation

All values are normalized to a 0–100 scale.
Example: Utility 95 
Efficiency 88 Reliability 94 Reputation 90
AUP Score = 92


4. AUPGuard.sol

This component handles economic safety. 
Users can specify: Maximum budget: $1 Maximum cost/task: $0.10 
Minimum AUP Score: 70 Then, before an agent executes a paid action: AUP Score >= 70? │ YES │ Cost <= user limit? │ YES │ ALLOW Otherwise: BLOCK Thus, AUP does more than just provide a rating; it serves as a layer of cost protection.

5.Data flow 

A simple example: 
The user runs Agent #001.
Task
Cost = $0.02
Result = Success

The evaluator submits the results: recordExecution( agentId, success, cost, utility ) The contract updates: 
Tasks: 101 → 102 Success: 94 → 95 Total Cost: +$0.02 Then, the score is recalculated. 
AUP Score 91 → 92


6.Anti-manipulation 

(MVP version) For the MVP, the following measures suffice: Agents cannot alter their own statistics. Only evaluators or authorized reporters can submit data. Each execution has a unique ID. Executions cannot be recorded twice. Statistics are calculated based on execution history. Feedback carries limited weight. New agents do not immediately receive a high score.


