# 🌟 Flare: AI Agent Monitoring App on Stellar

> **Built for Stellar Hacks: Agents | 8 Intelligence Categories | Real USDC Micropayments on Stellar Testnet**

**Autonomous intelligence agents that monitor the world, verify events, and alert you, powered by Stellar micro-payments.**

Flare transforms real-time monitoring from a passive, subscription-based experience into an active, **pay-per-query** mesh. By leveraging the Stellar network, Flare can hire specialized AI agents to monitor, verify, and cross-verify findings with near-zero friction.

### 🎥 Demo & Links

- **Demo Video**: [Click here to watch the demo](#[placeholder])
- **Live Backend**: [https://flare-f9yk.onrender.com](https://flare-f9yk.onrender.com)
- **Status**: Live on Stellar Testnet

### 📸 Screenshots

![Splash Screen](#[placeholder]) ![Home Dashboard](#[placeholder])
![Watcher List](#[placeholder]) ![Stellar Payments](#[placeholder])
![Confidence Score](#[placeholder]) ![Briefing Screen](#[placeholder])
![ROI Tracking](#[placeholder]) ![Ghost Rank](#[placeholder])

---

## 🛠️ Tech Stack

- **Mobile**: Flutter + Dart (BLoC Pattern, Dio, fl_chart, GetIt)
- **Backend**: Node.js + Express + TypeScript
- **Database**: PostgreSQL (Hosted on Render)
- **Blockchain**: Stellar Testnet + Soroban Smart Contracts
- **Payments**: X402-based direct Stellar USDC verification
- **Notifications**: Firebase Cloud Messaging (FCM)
- **Deployment**: Render (Auto-deploy via GitHub)

---

## 🌌 Stellar Integration

Flare is built with a **"Pay-per-Intelligence"** philosophy. Every data query performed by an agent is an on-chain event.

### How Verification Works

1. **Challenge**: When Flare queries a data service, the service returns a `402 Payment Required` challenge.
2. **Payment**: Flare signs and submits a Soroban `transfer` transaction on the user's USDC trustline.
3. **Proof**: The transaction hash is sent back to the service. The service verifies the payment status via the **Stellar Soroban RPC** before unlocking the data.

### Multi-Stage Verification Pipeline

For high-confidence findings, Flare executes a multi-transaction pipeline:

- **Initial Check**: 1 Transaction to fetch data.
- **Double-Check**: After 60 seconds, a 2nd transaction is triggered to verify the "Finding" still exists (preventing "dead findings").
- **Agent-to-Agent Collaboration**: A 3rd transaction is used to hire a _different_ agent (e.g., a News agent) to cross-verify the event from another angle.

### 🔗 Real Transaction Proofs (Testnet)

Below are real transactions generated during our demo runs:

- [Check: Flight Search](https://stellar.expert/explorer/testnet/tx/1a0b...#[placeholder])
- [Verification: News Cross-Check](https://stellar.expert/explorer/testnet/tx/2b1c...#[placeholder])
- [Budget: Top-up Event](https://stellar.expert/explorer/testnet/tx/3c2d...#[placeholder])
- **Total Demo Transactions**: 142

---

## 🧬 How It Works

1. **Deployment**: User creates a "Watcher" for a specific intent (e.g., "Paris Flights under $400").
2. **Smart Check**: Flare's scheduler triggers the check based on your chosen interval.
3. **Payment Check**: Flare initiates an **X402 handshake** with a specialized Data Service.
4. **Soroban Payment**: Flare pays the service (e.g., 0.008 USDC) directly on Stellar Testnet.
5. **Detection**: Flare's detection logic parses the response for "Findings."
6. **Double-Check**: The agent re-verifies the finding after a 60-second delay (second Stellar payment).
7. **Cross-Check**: The agent hires another agent (e.g., a News agent) to verify from a different angle (third Stellar payment).
8. **Confidence Score**: A score (0-100) is calculated based on freshness, verification success, history, cross-check results, and source reliability.

---

## 🧪 What's Real vs Simulated

Flare is a fully functional prototype designed for the **Stellar Hacks: Agents** hackathon. Here is the breakdown:

| Feature                | Status        | Technology                                            |
| :--------------------- | :------------ | :---------------------------------------------------- |
| **USDC Payments**      | **REAL**      | Verified on Stellar Testnet via Soroban               |
| **Wallet Management**  | **REAL**      | Creation, funding, and balance tracking on-chain      |
| **Budget Enforcement** | **REAL**      | Watchers pause automatically when USDC budget is hit  |
| **Multi-Agent Flow**   | **REAL**      | Automatic 2nd and 3rd payment cycles for verification |
| **Push Notifications** | **REAL**      | Delivered via Firebase Cloud Messaging                |
| **Confidence Scoring** | **REAL**      | Multi-factor logic based on chain verification        |
| **Intelligence Data**  | **SIMULATED** | Mock data sources designed to trigger demo scenarios  |

> [!NOTE]
> In a production environment, individual data service handlers (Flight, News, etc.) would be swapped with live integrations like Skyscanner, CoinGecko, and NewsAPI.

---

## 💼 Working Use Cases (Demo Ready)

Flare agents are demo-ready with specific cost-structures:

- **✈️ Flight Lows**: Detects historic price drops on specific routes.
  - _Cost_: 0.008 USDC per check.
- **💰 Crypto Volatility**: Monitoring for whale movements and technical price breakouts.
  - _Cost_: 0.005 USDC per check.
- **📊 Stock Alerts**: Real-time intraday volatility and dividend news.
  - _Cost_: 0.0035 USDC per check.
- **💼 Job Hunters**: Monitors for high-value senior roles with salary rank detection.
  - _Cost_: 0.006 USDC per check.
- **📰 News Monitoring**: Real-time keyword matching across intelligence feeds.
  - _Cost_: 0.003 USDC per check.
- **🛍️ Flash Deals**: Tracking "All-Time Low" prices for targeted electronics.
  - _Cost_: 0.004 USDC per check.
- **🏠 Real Estate**: Identifying 10%+ price drops in high-value neighborhoods.
  - _Cost_: 0.009 USDC per check.
- **⚽ Sports & Leisure**: Detecting ticket price crashes before major events.
  - _Cost_: 0.0045 USDC per check.

_Aspirational scenarios (Whale movements, RSI divergences, and Supply Chain hits) are on the [Future Roadmap](#future-roadmap)._

---

## ✨ Features

- **8 Intelligence Categories**: Flight, Crypto, News, Product, Job, Stock, Real Estate, Sports.
- **Voice-Powered Watchers**: Create complex watchers using simple voice commands.
- **One-Tap Templates**: Fast-start watchers using pre-set logic.
- **Live Payment Stream**: Visual visualization of Stellar transactions as they happen.
- **Double-Check System**: 60-second re-verification for high-fidelity alerts.
- **Agent-to-Agent Collab**: Seamless cross-verification between intelligence domains.
- **Ghost Score**: Gamified agent reliability ranking (Novice to Master).
- **Savings ROI Dashboard**: Track exactly how much USDC your agents saved you vs spent.
- **Spending Heatmap**: Visual calendar of your agentic monitoring spend.
- **Push Alerts**: Notifications with embedded confidence tiers (High/Medium/Low).
- **Morning Briefings**: Daily AI-generated summaries of all monitored findings.

---

## ⚙️ Setup Instructions

### Prerequisites

- Node.js 18+
- Flutter 3.x
- Firebase Account (for Google-Services.json)

### 1. Backend & Data Services

The intelligence services are integrated directly into the backend for the demo.

```bash
cd backend
npm install
cp .env.example .env # Fill in ENCRYPTION_KEY, OPERATOR_SECRET, and FIREBASE_CREDENTIALS
npm run dev # Starts both the main API and the mock X402 intelligence services
```

### 2. Flutter App

```bash
cd app
flutter pub get
# Update API_BASE_URL (Constants) to your backend URL (local or Render)
flutter run
```

### 3. Testnet Setup

```bash
# Initialize testnet wallets and trustlines
cd backend
npx tsx src/scripts/setup-wallets.ts
```

---

## 🚀 Next Features

- **Agentic Virtual Cards**: Allowing agents to issue temporary cards via Stellar anchors to act on findings (e.g., book the flight).
- **Local Currency Funding**: Direct fiat-to-USDC onramps using Stellar's global anchor network.
- **Self-Healing Watchers**: Agents that automatically adjust check intervals to optimize budget efficiency.

---

## 🏆 Submission

- **Hackathon**: [Stellar Hacks: Agents](https://stellar.org/hacks)
- **Team**: Boxkit Labs
- **GitHub**: [github.com/Boxkit-Labs/flare](https://github.com/Boxkit-Labs/flare)

---

_Built with ❤️ on Stellar._

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
