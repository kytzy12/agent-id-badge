# Submission materials — Binance Agent ID Hackathon
# Project: Agent ID Badge
# Project submission form: https://app.binance.com/uni-qr/user-survey/fb26d2bd25e04329b1ba77c7b3811d23
# (John fills it himself — requires Binance login. Deadline 9 Dec 2026 15:00 WIB.)
# Status: contract deployed + source verified. Website = GitHub Pages URL once the repo is created + Pages enabled (John creates the repo; Muse pushes the code).

## Project name
Agent ID Badge

## Website
(TODO after deploy — GitHub Pages URL of frontend/, e.g. https://kytzy12.github.io/agent-id-badge/
Fallback: GitHub repo URL https://github.com/kytzy12/agent-id-badge)

## Contract address (BNB Chain mainnet)
0x3DDe30F3e5E7D90191904CA34e1D42d29CF97f0A
Agent ID contract used: 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F
Deploy tx: 0xae9c8b54ebce535a50e9025ce58fd85efedf117e1385eca1f3b39f48d53289bf (block 134340916)
Source verified: Sourcify exact_match (job b56939f2-9356-4dd6-b5f1-64c9b0e116a4)
BscScan: https://bscscan.com/address/0x3DDe30F3e5E7D90191904CA34e1D42d29CF97f0A

## Reward receiving address
0x02962133fE4ed72B5d194c314348aa6D8Bcb6525

## Project description (for the form)
Agent ID Badge is a free achievement NFT for Agent ID holders on BNB Chain.
Any wallet that holds an Agent ID (name.ai) can mint exactly one badge, free of
charge (the minter only pays their own gas). The badge is a fully on-chain
ERC-721: name, description and SVG artwork are stored in the contract itself,
with no external server or IPFS dependency. The contract never accepts or
holds user funds. It exists to give Agent ID holders a simple, visible proof
of participation in the Agent ID ecosystem.

## How Agent ID is used (for the form)
The contract reads the official Agent ID registry
(0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F) on every mint: mint() calls
balanceOf(msg.sender) and only proceeds when the caller holds at least one
Agent ID. Wallets without an Agent ID cannot mint, and a wallet that loses
its Agent ID can no longer mint. The frontend checks the same balanceOf
before enabling the mint button, so Agent ID is the sole access control for
the whole product — identity, not just a label.

## Owner permissions (disclosed, as required by the rules)
- setBadgeName / setBadgeDescription: owner may update the badge name or
  description text only.
- No admin mint, no mintTo, no withdraw (the contract rejects all incoming
  funds), no pause, no freeze, no fees, no tax changes.
- Source code is open and verified on BscScan after deploy.

## What NOT to claim
- No returns, no passive income, no money-making promises anywhere.
- The badge is a free collectible, not an investment.
