const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);
  console.log("Account balance:", (await hre.ethers.provider.getBalance(deployer.address)).toString());

  // 1. Deploy AUPRegistry
  console.log("\n1. Deploying AUPRegistry...");
  const Registry = await hre.ethers.getContractFactory("AUPRegistry");
  const registry = await Registry.deploy();
  await registry.waitForDeployment();
  const registryAddress = await registry.getAddress();
  console.log("AUPRegistry deployed to:", registryAddress);

  // 2. Deploy AUPReputation
  console.log("\n2. Deploying AUPReputation...");
  const Reputation = await hre.ethers.getContractFactory("AUPReputation");
  const reputation = await Reputation.deploy(registryAddress);
  await reputation.waitForDeployment();
  const reputationAddress = await reputation.getAddress();
  console.log("AUPReputation deployed to:", reputationAddress);

  // 3. Deploy AUPGuard
  console.log("\n3. Deploying AUPGuard...");
  const Guard = await hre.ethers.getContractFactory("AUPGuard");
  const guard = await Guard.deploy(registryAddress, reputationAddress);
  await guard.waitForDeployment();
  const guardAddress = await guard.getAddress();
  console.log("AUPGuard deployed to:", guardAddress);

  console.log("\n========================================");
  console.log("DEPLOYMENT SUMMARY");
  console.log("========================================");
  console.log("Network:          ", hre.network.name);
  console.log("AUPRegistry:      ", registryAddress);
  console.log("AUPReputation:    ", reputationAddress);
  console.log("AUPGuard:         ", guardAddress);
  console.log("========================================");

  const fs = require("fs");
  const addresses = {
    network: hre.network.name,
    chainId: (await hre.ethers.provider.getNetwork()).chainId.toString(),
    deployer: deployer.address,
    AUPRegistry: registryAddress,
    AUPReputation: reputationAddress,
    AUPGuard: guardAddress,
    deployedAt: new Date().toISOString(),
  };

  fs.writeFileSync(
    `deployments-${hre.network.name}.json`,
    JSON.stringify(addresses, null, 2)
  );
  console.log(`\nAddresses saved to deployments-${hre.network.name}.json`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });