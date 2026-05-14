# web3-wallet-qa-lab

> 🇨🇳 中文 | [🇺🇸 English](./README.en.md)

Web3 钱包与 DApp 测试场 — 覆盖 JD 全栈技术点的 QA portfolio 项目。

## 项目目标

针对 Web3 钱包 QA 岗位 JD，把以下技术点全部落成可跑、可复现的代码：

- 助记词 / 私钥 / 签名（EIP-191 / EIP-712）
- 交易 / Gas / Nonce / 链上状态同步
- ERC-20 / ERC-721 / ERC-4337
- DeFi 全流程：Swap / 借贷 / 质押 / LP（fork mainnet 真打 Uniswap V3 + Aave V3）
- Extension 钱包自动化（Playwright + MetaMask）
- Mobile 钱包冒烟（Appium + MetaMask Mobile）
- 异常场景：Nonce 冲突、Gas Revert vs OOG、回滚、断网重连

## 技术栈

| 层            | 技术                                                        |
| ------------- | ----------------------------------------------------------- |
| 合约          | Solidity + Foundry                                          |
| 链环境        | Anvil（fork mainnet）                                       |
| Wallet Driver | TypeScript + viem                                           |
| Extension E2E | Playwright + MetaMask（自写 fixture，后期接 Synpress 对比） |
| Mobile E2E    | Appium + MetaMask Mobile（冒烟）                            |
| 单元测试      | vitest                                                      |
| 报告          | Allure                                                      |
| CI            | GitHub Actions                                              |

## 仓库结构

```
contracts/             Foundry — ERC-20 / 721 / 4337
chain/                 Anvil fork 启动 + 部署脚本
packages/
  wallet-driver/       viem 驱动层（HD / 签名 / Gas / Nonce / 事件）
  extension-e2e/       Playwright + MetaMask
  mobile-e2e/          Appium + MetaMask Mobile
docs/
  acceptance/          验收文档模板
  bug-reports/         缺陷模板与示例
  ux-feedback.md       体验优化建议
```

## 快速开始

```bash
pnpm install                  # 装依赖
cp .env.example .env          # 配置环境变量（填 Alchemy key）
# 详细分包跑测命令见各 package README（开发中）
```

## 开发规范

- Node ≥ 20
- TypeScript strict（含 `noUncheckedIndexedAccess` / `exactOptionalPropertyTypes`）
- Conventional Commits（commitlint 强制）
- pre-commit：lint-staged 自动格式化

## 进度

- [x] P0 — 仓库脚手架
- [ ] P1 — 合约层（ERC-20 / 721 / 4337）
- [ ] P2 — 链环境（Anvil fork）
- [ ] P3 — Wallet Driver（viem）
- [ ] P4 — Extension E2E
- [ ] P5 — Mobile 冒烟
- [ ] P6 — 异常场景
- [ ] P7 — 报告与文档

## 许可

MIT
