/**
 * deploy.js — Deploy CoordinationLog to Base Mainnet
 * 
 * Usage:
 *   npm install ethers
 *   PRIVATE_KEY=your_key node scripts/deploy.js
 * 
 * Or with Hardhat:
 *   npx hardhat run scripts/deploy.js --network base
 */

const { ethers } = require("ethers");
const fs = require("fs");
const path = require("path");

// ─── Config ───────────────────────────────────────────────────────────────────

const BASE_MAINNET_RPC = "https://mainnet.base.org";
const BASE_MAINNET_CHAIN_ID = 8453;

// ERC-8004 agent identity (from hackathon registration)
const AGENT_ADDRESS  = process.env.AGENT_ADDRESS  || "0x0000000000000000000000000000000000000001"; // replace with your ERC-8004 address
const HUMAN_ADDRESS  = process.env.HUMAN_ADDRESS  || "0x0000000000000000000000000000000000000002"; // replace with Reis's wallet

// ─── ABI (minimal — generated from CoordinationLog.sol) ───────────────────────

const ABI = [
  "constructor(address _agent, address _human)",
  "function startSession(string scenarioType, uint256 strikeCount, uint256 casualties, uint256 displaced) returns (uint256)",
  "function logDirective(uint256 sessionId, uint256 directiveNumber, string fromUnit, string toUnit, string reasoning, uint256 estimatedLivesSaved)",
  "function completeSession(uint256 sessionId, uint256 finalScore, uint256 totalLivesSaved, uint256 responseTimeSeconds)",
  "function getDirectives(uint256 sessionId) view returns (tuple(uint256,string,string,string,uint256,uint256)[])",
  "function getSessionSummary(uint256 sessionId) view returns (string,uint256,uint256,uint256,uint256,uint256,bool)",
  "event DirectiveIssued(uint256 indexed sessionId, uint256 indexed directiveNumber, string fromUnit, string toUnit, string reasoning, uint256 estimatedLivesSaved, uint256 coordinationScore, uint256 timestamp)",
  "event SessionStarted(uint256 indexed sessionId, string scenarioType, uint256 strikeCount, uint256 casualties, uint256 displaced, uint256 timestamp)",
  "event SessionCompleted(uint256 indexed sessionId, uint256 finalScore, uint256 totalLivesSaved, uint256 totalDirectives, uint256 responseTimeSeconds, uint256 timestamp)"
];

// ─── Bytecode placeholder (compile CoordinationLog.sol with solc or Hardhat) ──
// To compile: npx hardhat compile
// Then replace this with artifacts/contracts/CoordinationLog.sol/CoordinationLog.json bytecode

async function deploy() {
  console.log("╔══════════════════════════════════════════════════╗");
  console.log("║  CoordinationLog — Base Mainnet Deployment        ║");
  console.log("║  Global Coordination Agent × Reis Mesquita        ║");
  console.log("╚══════════════════════════════════════════════════╝\n");

  if (!process.env.PRIVATE_KEY) {
    console.error("❌ PRIVATE_KEY environment variable not set");
    console.error("   Usage: PRIVATE_KEY=0x... node scripts/deploy.js");
    process.exit(1);
  }

  const provider = new ethers.JsonRpcProvider(BASE_MAINNET_RPC);
  const wallet   = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

  console.log(`🔑 Deploying from: ${wallet.address}`);
  console.log(`🤖 Agent address:  ${AGENT_ADDRESS}`);
  console.log(`👤 Human address:  ${HUMAN_ADDRESS}`);

  const network = await provider.getNetwork();
  if (network.chainId !== BigInt(BASE_MAINNET_CHAIN_ID)) {
    console.error(`❌ Wrong network. Expected Base Mainnet (${BASE_MAINNET_CHAIN_ID}), got ${network.chainId}`);
    process.exit(1);
  }
  console.log(`✅ Connected to Base Mainnet (chain ${network.chainId})\n`);

  // Load compiled bytecode
  let bytecode;
  const artifactPath = path.join(__dirname, "../artifacts/contracts/CoordinationLog.sol/CoordinationLog.json");
  if (fs.existsSync(artifactPath)) {
    const artifact = JSON.parse(fs.readFileSync(artifactPath, "utf8"));
    bytecode = artifact.bytecode;
  } else {
    console.error("❌ Compiled artifact not found. Run: npx hardhat compile");
    process.exit(1);
  }

  console.log("🚀 Deploying CoordinationLog contract...");
  const factory  = new ethers.ContractFactory(ABI, bytecode, wallet);
  const contract = await factory.deploy(AGENT_ADDRESS, HUMAN_ADDRESS);

  console.log(`📝 TX hash: ${contract.deploymentTransaction().hash}`);
  console.log("⏳ Waiting for confirmation...");

  await contract.waitForDeployment();
  const address = await contract.getAddress();

  console.log(`\n✅ CONTRACT DEPLOYED`);
  console.log(`   Address: ${address}`);
  console.log(`   Basescan: https://basescan.org/address/${address}`);

  // Save deployment info
  const deployment = {
    contractAddress: address,
    deployedAt: new Date().toISOString(),
    deployedBy: wallet.address,
    agentAddress: AGENT_ADDRESS,
    humanAddress: HUMAN_ADDRESS,
    network: "base-mainnet",
    chainId: BASE_MAINNET_CHAIN_ID,
    txHash: contract.deploymentTransaction().hash,
    basescan: `https://basescan.org/address/${address}`,
  };

  fs.writeFileSync(
    path.join(__dirname, "../deployment.json"),
    JSON.stringify(deployment, null, 2)
  );
  console.log("\n💾 Deployment info saved to deployment.json");
  console.log("\n📋 Next step: Update CONTRACT_ADDRESS in src/crisis-coordinator.html");
  console.log(`   const CONTRACT_ADDRESS = "${address}";`);
}

deploy().catch(err => {
  console.error("❌ Deployment failed:", err.message);
  process.exit(1);
});
