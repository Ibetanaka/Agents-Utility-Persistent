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
        address agentAddress;
        address owner;
        string category;
        bool active;
        uint256 registeredAt;
    }

    uint256 public nextAgentId = 1;

    mapping(uint256 => Agent) public agents;
    mapping(address => uint256[]) private _ownerAgents;
    mapping(address => uint256) public agentAddressToId;

    event AgentRegistered(
        uint256 indexed agentId,
        address indexed agentAddress,
        address indexed owner,
        string category
    );

    event AgentStatusUpdated(uint256 indexed agentId, bool active);

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

    function setAgentActive(uint256 agentId, bool active) external {
        Agent storage agent = agents[agentId];
        require(agent.agentId != 0, "Agent does not exist");
        require(msg.sender == agent.owner, "Not agent owner");
        agent.active = active;
        emit AgentStatusUpdated(agentId, active);
    }

    function getAgentsByOwner(address owner) external view returns (uint256[] memory) {
        return _ownerAgents[owner];
    }

    function isActiveAgent(uint256 agentId) external view returns (bool) {
        Agent memory agent = agents[agentId];
        return agent.agentId != 0 && agent.active;
    }

    function getAgent(uint256 agentId) external view returns (Agent memory) {
        return agents[agentId];
    }
}