# Agents Utility Persistent (AUP)

**The reputation and economic safety layer for AI agents.**

AUP measures AI agent **utility, efficiency, reliability, and cost performance**, then converts it into a transparent on-chain **AUP Score (0–100)**.  
This helps users make safer and more economical decisions before executing an agent.

> Status: **MVP — Ready for Base Sepolia & Base Mainnet**

---

## Why AUP?

AI agents can consume unpredictable resources and costs.  
Users need a reliable, on-chain way to evaluate an agent **before** execution.

AUP provides:

- Agent Registry
- On-chain Reputation
- Utility Score
- Cost Efficiency Score
- Reliability Score
- Spending Guard (budget & risk limits)
- Anti-manipulation protection

---

## Smart Contracts

| Contract              | Description                                      |
|-----------------------|--------------------------------------------------|
| `AUPRegistry.sol`     | Register agents (ID, address, owner, category)   |
| `AUPReputation.sol`   | Record executions and calculate AUP Score        |
| `AUPGuard.sol`        | User-configurable spending & risk protection     |

### AUP Score Formula

AUP Score = (Utility × 40%) + (Efficiency × 30%) + (Reliability × 20%) + (Reputation × 10%)

- All component scores are normalized to **0–100**
- New agents receive a cold-start penalty until they complete at least 3 tasks

---

## Architecture

User
│
▼
AUP Registry          ← register agent
│
▼
Agent Executes Task
│
├─ Result
├─ Cost
└─ Utility feedback
│
▼
AUP Reputation        ← recordExecution()
│
▼
AUP Score (0-100)
│
▼
AUP Guard             ← canExecute() → ALLOW / BLOCK


---

## Quick Start

```bash
git clone https://github.com/Ibetanaka/Agents-Utility-Persistent.git
cd Agents-Utility-Persistent
npm install


Deploy to Base
1. Setup Environment

cp .env.example .env

Edit the .env file:
PRIVATE_KEY=0xYourPrivateKey
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
BASE_RPC_URL=https://mainnet.base.org
BASESCAN_API_KEY=YourBasescanApiKey   # optional


2. Compile

npx hardhat compile


3. Deploy to Base Sepolia (Testnet)

npx hardhat run scripts/deploy.js --network base-sepolia


4. Deploy to Base Mainnet

npx hardhat run scripts/deploy.js --network base

After deployment, contract addresses will be saved to deployments-base-sepolia.json or deployments-base.json.


5. Verify on Basescan (Optional)

npx hardhat verify --network base-sepolia <REGISTRY_ADDRESS>
npx hardhat verify --network base-sepolia <REPUTATION_ADDRESS> <REGISTRY_ADDRESS>
npx hardhat verify --network base-sepolia <GUARD_ADDRESS> <REGISTRY_ADDRESS> <REPUTATION_ADDRESS>


How to Use After Deployment:

1. Register an Agent

uint256 agentId = registry.registerAgent(agentAddress, "Research");

2. Authorize an Evaluator (owner only)

reputation.setEvaluator(evaluatorAddress, true);

3. Record an Execution (evaluators only)

reputation.recordExecution(
    agentId,
    executionId,   // unique bytes32
    true,          // success
    20000,         // cost
    92             // utility score 0-100
);


4. User configures Guard

guard.configureGuard(
    1000000,   // maxBudget
    50000,     // maxCostPerTask
    70         // minAupScore
);

5. Check before execution

(bool allowed, string memory reason) = guard.canExecute(user, agentId, estimatedCost);



Project Structure

├── contracts/
│   ├── AUPRegistry.sol
│   ├── AUPReputation.sol
│   └── AUPGuard.sol
├── scripts/
│   └── deploy.js
├── hardhat.config.js
├── package.json
├── .env.example
└── README.md


License
MIT



Goal: Become the economic reputation and safety infrastructure for autonomous AI agents on Base and beyond.

^•••^

