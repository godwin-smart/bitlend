# BitLend Protocol v2.0

## Decentralized Lending Protocol on Bitcoin Layer 2

[![Stacks](https://img.shields.io/badge/Built%20on-Stacks-orange)](https://stacks.co)
[![Bitcoin](https://img.shields.io/badge/Secured%20by-Bitcoin-f7931a)](https://bitcoin.org)
[![Clarity](https://img.shields.io/badge/Language-Clarity-blue)](https://clarity-lang.org)

## Overview

BitLend Protocol revolutionizes peer-to-peer lending by leveraging Bitcoin's security through Stacks Layer 2 technology. Our protocol enables users to create collateral-backed loans with dynamic risk management, automated liquidation mechanisms, and reputation-based lending scores.

### Key Features

- 🔒 **Multi-Asset Collateral Support** - Whitelist-based collateral management
- 📊 **Dynamic Risk Management** - Real-time liquidation thresholds
- 🏆 **Reputation System** - Credit scoring for borrowers
- 🚨 **Emergency Controls** - Circuit breaker functionality
- 📈 **Price Feed Integration** - Real-time asset valuation
- ⚡ **Automated Liquidation** - Time and value-based triggers

## System Architecture

### Core Components

```
┌─────────────────────────────────────────────────────────────┐
│                    BitLend Protocol                         │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐│
│  │   Loan Engine   │  │ Collateral Mgmt │  │ Price Feed Mgmt ││
│  │                 │  │                 │  │                 ││
│  │ • Loan Creation │  │ • Asset Whitelist│  │ • Price Updates ││
│  │ • Activation    │  │ • Validation    │  │ • Freshness    ││
│  │ • Liquidation   │  │ • Ratio Calc    │  │ • Threshold Calc││
│  └─────────────────┘  └─────────────────┘  └─────────────────┘│
│                                                               │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐│
│  │ Reputation Sys  │  │ Emergency Ctrl  │  │ Admin Functions ││
│  │                 │  │                 │  │                 ││
│  │ • Score Tracking│  │ • Circuit Breaker│  │ • Owner Mgmt   ││
│  │ • Penalty/Reward│  │ • Status Check  │  │ • Asset Mgmt   ││
│  │ • History       │  │ • Safety Halt   │  │ • Price Feed   ││
│  └─────────────────┘  └─────────────────┘  └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### Data Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │     Loans       │    │   User Loans    │                │
│  │                 │    │                 │                │
│  │ • loan-id       │    │ • active-loans  │                │
│  │ • borrower      │    │ • total-borrowed│                │
│  │ • amount        │    │                 │                │
│  │ • collateral    │    │                 │                │
│  │ • status        │    │                 │                │
│  │ • interest-rate │    │                 │                │
│  │ • duration      │    │                 │                │
│  └─────────────────┘    └─────────────────┘                │
│                                                             │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │ User Reputation │    │  Asset Prices   │                │
│  │                 │    │                 │                │
│  │ • repayments    │    │ • price         │                │
│  │ • defaults      │    │ • last-updated  │                │
│  │ • total-borrowed│    │                 │                │
│  │ • reputation    │    │                 │                │
│  └─────────────────┘    └─────────────────┘                │
│                                                             │
│  ┌─────────────────┐                                       │
│  │Collateral Assets│                                       │
│  │                 │                                       │
│  │ • asset         │                                       │
│  │ • is-active     │                                       │
│  └─────────────────┘                                       │
└─────────────────────────────────────────────────────────────┘
```

## Contract Architecture

### Core Functions

#### **Loan Management**

- `create-loan-request` - Create new collateral-backed loan
- `activate-loan` - Activate pending loan
- `liquidate-loan` - Execute loan liquidation

#### **Administrative Functions**

- `set-contract-owner` - Transfer ownership
- `toggle-emergency-stop` - Circuit breaker control
- `add-collateral-asset` - Whitelist new assets
- `update-asset-price` - Update price feeds

#### **Read-Only Functions**

- `get-loan` - Retrieve loan details
- `get-user-reputation` - Get borrower reputation
- `calculate-total-due` - Calculate repayment amount
- `get-contract-status` - Check emergency status

### Security Features

#### **Multi-Layer Validation**

- Emergency stop mechanism
- Collateral ratio enforcement (200% minimum)
- Asset whitelist validation
- Price feed freshness checks
- Duration and interest rate limits

#### **Risk Management**

- Dynamic liquidation thresholds
- Dual liquidation triggers (time + value)
- Reputation-based scoring
- Maximum loan duration limits

## Data Flow

### Loan Creation Process

```
User Request → Validation → Collateral Check → Price Feed → Loan Creation
     ↓              ↓             ↓              ↓            ↓
┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐
│ Amount  │   │Contract │   │Asset    │   │Current  │   │Store    │
│Duration │→  │Active?  │→  │Approved?│→  │Price    │→  │Loan     │
│Interest │   │Valid    │   │Ratio    │   │Fresh?   │   │Update   │
│Collat.  │   │Params?  │   │>200%?   │   │         │   │User     │
└─────────┘   └─────────┘   └─────────┘   └─────────┘   └─────────┘
```

### Liquidation Process

```
Trigger Check → Validation → Liquidation → Reputation Update
      ↓              ↓            ↓              ↓
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│Time     │    │Loan     │    │Update   │    │Penalty  │
│Expired? │ OR │Active?  │ →  │Status   │ →  │Applied  │
│Price    │    │Emergency│    │→LIQUID  │    │Score    │
│Drop?    │    │Stop?    │    │         │    │Updated  │
└─────────┘    └─────────┘    └─────────┘    └─────────┘
```

## Protocol Parameters

| Parameter | Value | Description |
|-----------|--------|-------------|
| `MIN-COLLATERAL-RATIO` | 200% | Minimum collateral coverage |
| `MAX-INTEREST-RATE` | 50% | Maximum annual interest rate |
| `MIN-DURATION` | 1 day | Minimum loan duration |
| `MAX-DURATION` | 1 year | Maximum loan duration |
| `LIQUIDATION-THRESHOLD` | 80% | Collateral value threshold |
| `MAX-PRICE-AGE` | 1 day | Maximum price data age |
| `REPUTATION_PENALTY` | 20 points | Default penalty |
| `REPUTATION_REWARD` | 10 points | Successful repayment reward |

## Getting Started

### Prerequisites

- Stacks CLI
- Clarinet (for testing)
- Node.js (for frontend integration)

### Deployment

1. **Clone the repository**

   ```bash
   git clone https://github.com/godwin-smart/bitlend.git
   cd bitlend-protocol
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Run tests**

   ```bash
   clarinet test
   ```

4. **Deploy to testnet**

   ```bash
   clarinet deploy --testnet
   ```

### Usage Example

```clarity
;; Create a loan request
(contract-call? .bitlend-protocol create-loan-request 
    u1000000    ;; 1 STX loan amount
    u2000000    ;; 2 STX collateral
    "STX"       ;; Collateral asset
    u144000     ;; 100 day duration
    u1000       ;; 10% interest rate
)

;; Activate the loan (admin only)
(contract-call? .bitlend-protocol activate-loan u1)

;; Check loan status
(contract-call? .bitlend-protocol get-loan u1)
```

## Security Considerations

- **Emergency Stop**: Protocol can be halted in critical situations
- **Price Feed Validation**: Ensures price data is fresh and accurate
- **Collateral Enforcement**: Minimum 200% collateral ratio required
- **Reputation System**: Tracks borrower history and applies penalties
- **Asset Whitelisting**: Only approved assets can be used as collateral

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
