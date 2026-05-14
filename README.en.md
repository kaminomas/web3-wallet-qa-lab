# web3-wallet-qa-lab

> [🇨🇳 中文](./README.md) | 🇺🇸 English

Web3 wallet & DApp QA testing lab — a portfolio project covering every technical point from a Web3 wallet QA job description.

## Goals

End-to-end testing coverage for:

- Mnemonic / private key / signing (EIP-191 / EIP-712)
- Transactions / Gas / Nonce / on-chain state sync
- ERC-20 / ERC-721 / ERC-4337
- DeFi flows: Swap / Lend / Stake / LP (real Uniswap V3 + Aave V3 on forked mainnet)
- Extension wallet automation (Playwright + MetaMask)
- Mobile wallet smoke (Appium + MetaMask Mobile)
- Edge cases: Nonce conflicts, Revert vs OOG, reorgs, RPC reconnection

## Stack

| Layer         | Tech                                                   |
| ------------- | ------------------------------------------------------ |
| Contracts     | Solidity + Foundry                                     |
| Chain         | Anvil (mainnet fork)                                   |
| Wallet Driver | TypeScript + viem                                      |
| Extension E2E | Playwright + MetaMask (custom fixture, Synpress later) |
| Mobile E2E    | Appium + MetaMask Mobile (smoke)                       |
| Unit tests    | vitest                                                 |
| Reports       | Allure                                                 |
| CI            | GitHub Actions                                         |

## Quick Start

```bash
pnpm install
cp .env.example .env   # fill in Alchemy key
```

## Progress

- [x] P0 — Scaffolding
- [ ] P1 — Contracts (ERC-20 / 721 / 4337)
- [ ] P2 — Chain env (Anvil fork)
- [ ] P3 — Wallet Driver (viem)
- [ ] P4 — Extension E2E
- [ ] P5 — Mobile smoke
- [ ] P6 — Edge cases
- [ ] P7 — Reports & docs

## License

MIT
