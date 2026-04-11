# Flare: AI Agents That Pay for Intelligence on Stellar

> **142 real Stellar transactions. 8 intelligence categories. Hybrid X402 + MPP payment channels. Zero subscriptions.**

### What We Built

Flare is a mobile app where autonomous AI agents monitor flights, crypto, stocks, news, products, jobs, real estate, and events, paying for every data query with real USDC micropayments on Stellar. Agents verify findings with double-checks, cross-verify with other agents, and only alert you when something actually matters. You wake up to a morning briefing that cost $0.03.

### What Makes Flare Different

| Capability                                                                  | Proof                                                                                                                                                                                                                                                      |
| :-------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Real USDC payments** for every data query                                 | [Verify on Stellar](https://stellar.expert/explorer/testnet/tx/7d19cc90ff4706c0f2e0bd5b73ad110cb8bc0c7953153ffbd07baee91e985830)                                                                                                                           |
| **MPP payment channels** for high-frequency monitoring                      | [Channel Open](https://stellar.expert/explorer/testnet/tx/cd16c2f33f257bfd5e9a3f18abf8308c850b5bcd0ace4c65fb553c2aabc18732) / [Channel Close](https://stellar.expert/explorer/testnet/tx/426a6037c26adeb5aba44ab14b3941c6b74387fe26d1fb6d92dfb6e3b319fd34) |
| **Hybrid X402 + MPP routing**, system auto-selects the optimal payment rail | Low-frequency uses X402. High-frequency uses MPP channels                                                                                                                                                                                                  |
| **Double-check verification**, findings confirmed with a 2nd payment        | Prevents false alerts from data glitches                                                                                                                                                                                                                   |
| **Agent-to-agent collaboration**, agents hire other agents to cross-verify  | Flight agent hires News agent to check travel advisories                                                                                                                                                                                                   |
| **50% fewer on-chain transactions** with MPP                                | 3 on-chain txs instead of 6 for the same work                                                                                                                                                                                                              |

---

### Demo and Links

- **Demo Video**: [Watch the 3-minute demo](#) <!-- Replace with real link -->
- **Live Backend**: [https://flare-f9yk.onrender.com](https://flare-f9yk.onrender.com)
- **Live on**: Stellar Testnet with real USDC micropayments

### Screenshots

<!-- Replace placeholders with real screenshot paths -->

| Home Dashboard | Finding Detail | Live Payment Stream | Morning Briefing |
| :------------: | :------------: | :-----------------: | :--------------: |
|   ![Home](#)   | ![Finding](#)  |    ![Stream](#)     |  ![Briefing](#)  |

| Wallet and Savings | Watcher Creation | Confidence Score | Stellar Proof |
| :----------------: | :--------------: | :--------------: | :-----------: |
|    ![Wallet](#)    |   ![Create](#)   | ![Confidence](#) |  ![Proof](#)  |

---

## Verified Stellar Transactions

Every transaction below is real. Click any link to verify on Stellar Explorer.

### X402 Payments (Per-Check)

| Check Type               | Transaction        | Explorer                                                                                                              |
| :----------------------- | :----------------- | :-------------------------------------------------------------------------------------------------------------------- |
| Flight price check       | `7d19cc90ff470...` | [Verify](https://stellar.expert/explorer/testnet/tx/7d19cc90ff4706c0f2e0bd5b73ad110cb8bc0c7953153ffbd07baee91e985830) |
| Wallet USDC trustline    | `7de4318994026...` | [Verify](https://stellar.expert/explorer/testnet/tx/7de4318994026da621bbc21d53f94000ac861b66dc0b423c30c7c1f2f9e0d4bb) |
| First x402 payment proof | `4ce1417e06fc4...` | [Verify](https://stellar.expert/explorer/testnet/tx/4ce1417e06fc4783dc06b349d9b880cfb4772a97d759b4e058baa62fac88b90f) |

### MPP Payment Channels

| Operation                | Transaction        | Explorer                                                                                                              |
| :----------------------- | :----------------- | :-------------------------------------------------------------------------------------------------------------------- |
| Channel deploy and init  | `a203a5a5af744...` | [Verify](https://stellar.expert/explorer/testnet/tx/a203a5a5af7449c6364857aefb73937bfb3011427b622388b2ca22ef9bdc9416) |
| Channel open (fund)      | `cd16c2f33f257...` | [Verify](https://stellar.expert/explorer/testnet/tx/cd16c2f33f257bfd5e9a3f18abf8308c850b5bcd0ace4c65fb553c2aabc18732) |
| 4 off-chain payments     | No on-chain txs    | Proofs signed locally via Ed25519                                                                                     |
| Channel close and settle | `426a6037c26ad...` | [Verify](https://stellar.expert/explorer/testnet/tx/426a6037c26adeb5aba44ab14b3941c6b74387fe26d1fb6d92dfb6e3b319fd34) |

**Result**: 5 data queries executed. Only 2 on-chain transactions needed (open + close). The 4 off-chain payments settled atomically at channel close.

### Soroban Contracts Deployed

| Contract                  | Address                                                    | Purpose                   |
| :------------------------ | :--------------------------------------------------------- | :------------------------ |
| One-Way Channel (WASM)    | `07c7d7fc...`                                              | MPP payment channel logic |
| Channel Instance          | `CCF6KCSVWEWOVTFNA24Y2JLFPVZJ6TIF5UDDVGUINBZIW6BAZG4KYE5R` | Testnet deployment        |
| Channel Instance (active) | `CBERIDS5QUNUSECMGVAVVPYJG5YPUU4E4XXBZ72K2PXTX2H4UCSQK7M6` | Latest working channel    |

---

## Tech Stack

| Layer             | Technology                                                                     |
| :---------------- | :----------------------------------------------------------------------------- |
| **Mobile**        | Flutter + Dart (BLoC, Dio, fl_chart, GetIt)                                    |
| **Backend**       | Node.js + Express + TypeScript                                                 |
| **Database**      | PostgreSQL (Render) with SQLite fallback                                       |
| **Blockchain**    | Stellar Testnet + Soroban Smart Contracts + USDC                               |
| **X402 Payments** | Custom stellarPaywall middleware with direct Soroban RPC verification          |
| **MPP Channels**  | one-way-channel Soroban contract + @stellar/mpp SDK + Ed25519 off-chain proofs |
| **Notifications** | Firebase Cloud Messaging                                                       |
| **Deployment**    | Render (auto-deploy from GitHub)                                               |

---

## How Flare's Payment System Works

Flare runs a hybrid payment architecture, the first of its kind in this hackathon. It combines two Stellar payment protocols to optimize for both cost and speed.

### X402 Flow (for low-frequency watchers such as flights, real estate, jobs)

When a watcher checks infrequently (every 6 hours or more), Flare uses a direct per-check payment. The scheduler triggers a check, the data service returns a 402 Payment Required challenge, Flare signs and submits a Soroban USDC transfer, then sends the transaction hash back to the service. The service verifies the payment on-chain via Soroban RPC and returns the data. This costs one Stellar transaction per query.

### MPP Flow (for high-frequency watchers such as crypto, stocks)

When a watcher checks frequently (more than once every 6 hours), Flare opens an MPP payment channel. This involves deploying a one-way-channel Soroban contract, depositing USDC into it, and then executing all subsequent checks off-chain using Ed25519 signed cumulative commitments. The data service verifies each proof locally without touching the blockchain. When the session ends or the budget runs low, the channel closes with a single on-chain transaction that settles the total amount owed. This means two Stellar transactions total (open and close), regardless of how many checks were executed in between.

### How the Router Decides

The payment router automatically selects the right protocol based on the watcher's check interval. If the interval is 6 hours or more, it uses X402. If the interval is under 6 hours, it opens an MPP channel. Users never need to know or care about the underlying payment rail.

### Multi-Stage Verification

When a finding is detected, Flare does not simply alert the user. It runs a verification pipeline. First, the initial check detects the finding and pays the data service (first Stellar payment). After 60 seconds, a second check re-verifies that the finding still holds (second Stellar payment). Then a different agent is hired to cross-verify from another angle, for example a flight finding triggers a news check for travel advisories (third Stellar payment). Finally, a confidence score from 0 to 100 is calculated based on five factors: data freshness, verification status, historical consistency, cross-check results, and source reliability. Only then is the user notified.

This means up to three Stellar transactions per finding, each one verifiable on-chain.

---

## The 8 Intelligence Categories

| Category              | What It Monitors                                                 | Cost Per Check |
| :-------------------- | :--------------------------------------------------------------- | :------------- |
| **Flights**           | Airline prices, error fares, historical lows, specific carriers  | 0.008 USDC     |
| **Crypto**            | Coin prices, portfolio value, pair ratios, volume spikes         | 0.005 USDC     |
| **Stocks**            | Stock prices, 52-week records, earnings, insider trades          | 0.004 USDC     |
| **News**              | Keywords, company mentions, sentiment, multi-source verification | 0.005 USDC     |
| **Products**          | Multi-store comparison, price drops, back-in-stock, wishlists    | 0.006 USDC     |
| **Jobs**              | Role matching, company watching, salary trends, hot jobs         | 0.007 USDC     |
| **Real Estate**       | New listings, price reductions, neighborhood trends              | 0.008 USDC     |
| **Sports and Events** | Ticket prices, score alerts, event discovery                     | 0.005 USDC     |

---

## System Architecture

Flare is composed of four layers that work together to deliver autonomous, paid intelligence.

**The Flutter mobile app** is the user-facing layer. It handles watcher creation (including voice input and templates), displays findings with confidence scores, shows the live payment stream visualization, renders the wallet with savings analytics, and delivers push notifications. The app communicates with the backend over HTTPS and connects to the WebSocket server for real-time streaming data.

**The Express backend** runs on Render and manages all server-side logic. It contains the scheduler (which triggers checks at configured intervals), the payment router (which decides between X402 and MPP for each check), the check executor (which calls data services and processes responses), the finding detector (which analyzes data against alert conditions), the verification pipeline (double-check and cross-check), the confidence scorer, the morning briefing generator, and the notification sender. It also manages user wallets, encrypts Stellar secret keys, and tracks budgets per watcher. The backend stores all state in PostgreSQL.

**The data services** are Express endpoints protected by the stellarPaywall middleware. Each service covers one intelligence category (flights, crypto, news, products, jobs, stocks, real estate, sports). The middleware accepts both X402 payments (via the x-stellar-tx header containing a verified transaction hash) and MPP payments (via the x-mpp-proof header containing a signed cumulative commitment). For the hackathon demo, these services return enriched mock data designed to trigger realistic findings. In production, they would connect to real APIs like Skyscanner, CoinGecko, and NewsAPI.

**The Stellar layer** handles all financial operations. For X402, this means individual Soroban USDC transfers verified via RPC. For MPP, this means deploying one-way-channel Soroban contracts, funding them with USDC deposits, signing off-chain Ed25519 commitments for each check, and settling the net amount when the channel closes. All transactions execute on Stellar Testnet using the USDC token contract.

---

## Feature List

**Payment Infrastructure**

- Hybrid X402 + MPP payment architecture
- Real USDC micropayments on Stellar testnet
- MPP payment channels with off-chain settlement
- WebSocket streaming with MPP proof exchange
- Automatic payment rail selection based on check frequency

**Agent Intelligence**

- 8 monitoring categories with enriched parameters
- Double-check finding verification (2nd Stellar payment)
- Agent-to-agent collaboration (3rd Stellar payment)
- Confidence scoring (0 to 100) based on 5 verification factors
- Agent reasoning chains visible in check history
- Finding detection with airline-specific, portfolio, sentiment, and multi-store modes

**User Experience**

- Voice-powered watcher creation
- One-tap templates for quick setup
- Live Stellar payment stream visualization
- Ghost Score, a gamified agent efficiency ranking
- Savings ROI dashboard ($715 saved vs $3.47 spent)
- Spending heatmap calendar
- Stellar transaction proof screen
- Push notifications with confidence scores
- Daily morning briefings with overnight summaries
- Per-watcher analytics with price trend charts

---

## What's Real vs Simulated

| Feature                  | Status        | Details                                                              |
| :----------------------- | :------------ | :------------------------------------------------------------------- |
| USDC Payments (X402)     | **REAL**      | Every check equals a real Soroban USDC transfer on Stellar testnet   |
| MPP Payment Channels     | **REAL**      | One-way-channel contract deployed, channels open and close on-chain  |
| MPP Off-Chain Proofs     | **REAL**      | Ed25519 signed cumulative commitments, verified locally              |
| WebSocket Streaming      | **REAL**      | Live data frames with MPP proof exchange                             |
| Wallet Management        | **REAL**      | Keypair generation, funding, trustlines, balance tracking            |
| Budget Enforcement       | **REAL**      | Watchers auto-pause when USDC budget exhausted                       |
| Multi-Agent Verification | **REAL**      | Double-check plus cross-check equals up to 3 Stellar txs per finding |
| Confidence Scoring       | **REAL**      | 5-factor scoring algorithm based on on-chain verification            |
| Push Notifications       | **REAL**      | Firebase Cloud Messaging with deep linking                           |
| Data Sources             | **SIMULATED** | Mock services with realistic data patterns                           |

**Why mock data?** Integrating 8 real-time APIs (Skyscanner, CoinGecko, etc.) would cost thousands in API fees and risk rate-limiting during judging. The mock data engine produces realistic patterns that trigger the finding detection, verification pipeline, and confidence scoring, which is where the real engineering lives. In production, swapping mock handlers for real APIs is a configuration change, not an architecture change.

---

## Setup Instructions

### Prerequisites

- Node.js 18+
- Flutter 3.x
- Firebase project (for push notifications)

### 1. Backend

```bash
cd backend
npm install
cp .env.example .env
# Fill in: ENCRYPTION_KEY, SERVICE_OPERATOR_SECRET, DATABASE_URL,
# FIREBASE credentials, MPP_CHANNEL_WASM_HASH
npm run dev
```

### 2. Flutter App

```bash
cd app
flutter pub get
# Update API_BASE_URL in lib/core/config/app_constants.dart
flutter run
```

### 3. Testnet Wallets

```bash
cd backend
npx tsx src/scripts/setup-wallets.ts
```

### 4. Run Integration Test

```bash
# Verify X402 + MPP + Streaming all work
npx tsx src/scripts/test-mpp-integration.ts
```

---

## Future Roadmap

- **Agentic Virtual Cards**: agents issue temporary Stellar-anchored cards to act on findings (book the flight, buy the product)
- **Fiat Onramp**: fund your agent budget with local currency via Stellar anchors
- **Self-Healing Watchers**: agents optimize their own check intervals based on hit rate
- **Real Data Integrations**: Skyscanner, CoinGecko, NewsAPI, Indeed, Zillow, StubHub
- **Mainnet Deployment**: transition from testnet to production USDC

---

## In the Demo Video You Will See

- Voice-powered watcher creation ("Watch ANA flights to Tokyo under $800")
- Live Stellar payment stream visualization
- Agent reasoning: "Price $789 is below $800 threshold, ALERT"
- Double-check: "Re-verifying... Confirmed" (2nd Stellar tx)
- Agent-to-agent: "Cross-checked travel advisories, all clear" (3rd Stellar tx)
- Push notification with 94% confidence score
- Finding detail with 3 Stellar transaction proofs
- Morning briefing: 22 checks overnight, $0.058 cost, $629 estimated savings
- Ghost Score: 87 out of 100, Agent Pro
- Savings dashboard: "$0.85 per month vs $58 in subscriptions"
- Spending heatmap showing 45 days of agent activity
- Stellar explorer showing real verified transactions

---

## Submission

- **Hackathon**: [Stellar Hacks: Agents](https://stellar.org/hacks)
- **Team**: Boxkit Labs
- **GitHub**: [github.com/Boxkit-Labs/flare](https://github.com/Boxkit-Labs/flare)

## License

MIT. See [LICENSE](LICENSE) for details.

---

_Built with real Stellar micropayments. Every transaction verifiable on-chain._
