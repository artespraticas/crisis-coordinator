# AGENTS.md — Global Coordination Agent / Crisis Coordinator

## What This System Does

This is an AI-powered disaster response coordination dashboard. It simulates a city under crisis (war strike scenario) and deploys an AI agent (Claude Sonnet) to coordinate emergency resources across 12 city nodes in real time.

## Live Demo

**URL:** https://crisis-coordinator.vercel.app *(update with actual Vercel URL)*

To interact:
1. Open the dashboard
2. Click **⚡ Strike Event** to trigger a war strike scenario
3. Click **◈ Activate Agent** to deploy the AI coordinator
4. Watch the agent stream live reasoning and issue directives across the city grid

## On-Chain Identity

- **Contract:** `0xb0DB76F7593e5dB24B58108C2BEBaF462b351B98`
- **Network:** Base Mainnet (Chain ID 8453)
- **Explorer:** https://basescan.org/address/0xb0DB76F7593e5dB24B58108C2BEBaF462b351B98

### Contract Interface (for agentic judges)

```solidity
function startSession(string calldata scenarioType) external returns (uint256 sessionId)
function logDirective(uint256 sessionId, uint256 num, string calldata fromUnit, string calldata toUnit, string calldata reasoning) external
function completeSession(uint256 sessionId, uint256 score, uint256 livesSaved) external
```

You can read all logged sessions and events on Basescan.

## AI Agent Behaviour

The agent receives a full JSON snapshot of the city simulation state including:
- All 12 unit statuses (hospitals, rescue teams, depots, shelters, comms hub)
- Casualty counts and resource conflicts
- Strike zone locations

It responds with:
- Numbered directives (`DIRECTIVE 1:`, `DIRECTIVE 2:` etc.)
- A `COORDINATION_SCORE: N` at the end
- Each directive triggers an animated map response

## Tech Stack

- **AI Model:** claude-sonnet-4-20250514 (Anthropic API, streaming)
- **Smart Contract:** Solidity 0.8.20 on Base Mainnet
- **Frontend:** Vanilla HTML/CSS/JS (zero dependencies, single file)
- **Deployment:** Vercel

## Repository Structure

```
src/crisis-coordinator.html   ← Full self-contained app
contracts/CoordinationLog.sol ← Deployed Solidity contract
scripts/deploy.js             ← Deployment script (ethers v5)
docs/vision.md                ← Project vision
AGENTS.md                     ← This file
README.md                     ← Human-readable overview
```

## Builder

**Reis Mesquita (Claudio)** — [@artespraticas](https://twitter.com/artespraticas)
Human + AI team: Claudio + Claude (Anthropic)
