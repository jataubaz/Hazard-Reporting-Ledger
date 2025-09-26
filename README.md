# ⚠️ Hazard Reporting Ledger

A transparent blockchain-based safety incident reporting system that empowers workers to document hazards, spills, and safety violations while holding companies accountable through immutable records.

## 🎯 Overview

The Hazard Reporting Ledger creates an uncensorable, transparent platform where:
- 👷 Workers can report safety incidents without fear of retaliation
- 🏭 Companies are held accountable through public records
- 🔍 Safety inspectors can verify and validate reports
- 📊 Stakeholders can track safety metrics and trends
- ⚖️ Evidence is preserved immutably for legal proceedings

## 🛡️ Key Features

### 📝 Incident Reporting
- Detailed hazard documentation with severity levels
- Evidence hash storage for proof attachment
- Witness addition capability
- Location and timestamp tracking
- Multiple incident type categories

### ✅ Verification System
- Authorized safety inspector verification
- Third-party validation process
- Credibility scoring for reporters
- Verification notes and authenticity confirmation

### 🏭 Company Accountability
- Company registration and verification
- Safety score tracking
- Response requirement system
- Resolution tracking with compensation
- Risk score calculations

### 📊 Comprehensive Metrics
- Platform-wide statistics
- Company safety profiles
- Reporter credibility scores
- Incident category analytics
- Critical incident tracking

## 🚀 Quick Start

### 1. Register a Company

```clarity
(contract-call? .Hazard-Reporting-Ledger register-company "ACME Manufacturing" "Industrial")
```

### 2. Submit a Hazard Report

```clarity
(contract-call? .Hazard-Reporting-Ledger submit-hazard-report
    'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7  ;; company principal
    "Chemical Spill"                              ;; incident type
    u"Major chemical leak in warehouse B, inadequate containment measures"  ;; description
    "Warehouse B, Section 3, Floor 2"             ;; location
    u4                                             ;; severity (1-5)
    u145000)                                       ;; incident date (block height)
```

### 3. Add Evidence Hash

```clarity
(contract-call? .Hazard-Reporting-Ledger add-evidence-hash 
    u1                                             ;; report-id
    0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef)  ;; evidence hash
```

### 4. Add Witnesses

```clarity
(contract-call? .Hazard-Reporting-Ledger add-witness 
    u1                                             ;; report-id
    'SP3FGQ8Z7JY9BWYZ5WM53E0M9NK7WHJF0691NZ159)  ;; witness principal
```

### 5. Verify Report (Inspector Only)

```clarity
(contract-call? .Hazard-Reporting-Ledger verify-report 
    u1                                             ;; report-id
    u"Confirmed chemical spill with environmental impact")  ;; verification notes
```

### 6. Company Response

```clarity
(contract-call? .Hazard-Reporting-Ledger submit-company-response
    u1                                             ;; report-id
    u"We acknowledge the incident and have initiated cleanup"  ;; response
    u"Emergency response team deployed immediately"  ;; action taken
    u"New containment protocols implemented")        ;; prevention measures
```

### 7. Resolve Incident

```clarity
(contract-call? .Hazard-Reporting-Ledger resolve-incident 
    u1                                             ;; report-id
    u1000000000)                                   ;; compensation in microSTX
```

## 📊 Severity Levels

| Level | Name | Value | Description |
|-------|------|-------|-------------|
| 🔴 | Critical | 5 | Life-threatening, immediate danger |
| 🟠 | High | 4 | Serious hazard, potential for major injury |
| 🟡 | Medium | 3 | Moderate risk, requires prompt attention |
| 🔵 | Low | 2 | Minor hazard, minimal immediate risk |
| ⚪ | Minor | 1 | Negligible risk, noted for records |

## 📈 Report Status Flow

```
pending → verified → investigating → resolved
                ↓
            disputed
```

## 🔍 Read Functions

### Get Report Details
```clarity
(contract-call? .Hazard-Reporting-Ledger get-report u1)
```

### Get Company Profile
```clarity
(contract-call? .Hazard-Reporting-Ledger get-company-profile 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

### Get Platform Statistics
```clarity
(contract-call? .Hazard-Reporting-Ledger get-platform-statistics)
```

### Calculate Company Risk Score
```clarity
(contract-call? .Hazard-Reporting-Ledger calculate-company-risk-score 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

### Get Reporter Profile
```clarity
(contract-call? .Hazard-Reporting-Ledger get-reporter-profile 'SP3FGQ8Z7JY9BWYZ5WM53E0M9NK7WHJF0691NZ159)
```

### Get Incident Category Statistics
```clarity
(contract-call? .Hazard-Reporting-Ledger get-incident-category-stats "Chemical Spill")
```

## 👮 Safety Inspector Authorization

Only authorized safety inspectors can verify reports:

```clarity
(contract-call? .Hazard-Reporting-Ledger authorize-inspector 
    'SP3FGQ8Z7JY9BWYZ5WM53E0M9NK7WHJF0691NZ159   ;; inspector principal
    "John Smith"                                   ;; name
    "OSHA")                                        ;; organization
```

## 🏭 Company Verification

Platform owner can verify legitimate companies:

```clarity
(contract-call? .Hazard-Reporting-Ledger verify-company 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

## 📊 Safety Scoring System

### Company Safety Score
- Starts at 100 points
- Decreases with each report (severity × 2 points)
- Increases by 5 points for resolved incidents
- Cannot go below 0

### Reporter Credibility Score
- Starts at 100 points
- Increases by 10 points per report
- Used to establish reporter reliability

### Risk Score Calculation
```
Risk Score = (Critical Reports × 10 + Total Reports × 2) / Resolved Reports
```
*Higher scores indicate higher risk*

## 🛡️ Security Features

- Immutable report storage
- Evidence hash preservation
- Witness testimony recording
- Timestamp verification
- Company response tracking
- Dispute mechanism

## 📝 Error Codes

| Code | Error | Description |
|------|-------|-------------|
| u100 | err-owner-only | Admin function only |
| u101 | err-company-not-found | Company not registered |
| u102 | err-report-not-found | Report ID doesn't exist |
| u103 | err-already-verified | Report already verified |
| u105 | err-invalid-severity | Severity must be 1-5 |
| u108 | err-not-reporter | Only reporter can perform action |
| u109 | err-not-verifier | Not authorized inspector |
| u112 | err-not-company | Only company can respond |

## 🎯 Benefits

### For Workers
- 🛡️ Protected whistleblowing
- 📝 Permanent incident records
- 👥 Witness support system
- 💰 Potential compensation

### For Companies
- 📊 Track safety metrics
- 🔄 Improve safety protocols
- 📈 Build trust through transparency
- ⚖️ Legal compliance documentation

### For Regulators
- 🔍 Real-time incident monitoring
- 📊 Industry-wide statistics
- 🎯 Target inspections effectively
- 📝 Evidence for enforcement

## 📊 Contract Statistics

- Total Functions: 18
- Public Functions: 11
- Read-Only Functions: 8
- Private Functions: 4
- Data Maps: 7
- Error Codes: 16

## 🌟 Future Enhancements

- 🤖 AI-powered incident pattern detection
- 📱 Mobile reporting application
- 🌐 Cross-chain incident sharing
- 📸 IPFS integration for evidence storage
- 🏆 Safety achievement NFTs
- 💼 Insurance premium calculations

## 🤝 Contributing

We welcome contributions that enhance worker safety and corporate accountability. Please ensure all changes maintain the integrity of the reporting system.

## ⚠️ Disclaimer

This system is designed to supplement, not replace, official safety reporting channels. Always follow proper safety protocols and report emergencies to appropriate authorities.

## 📄 License

This smart contract promotes workplace safety and transparency on the Stacks blockchain.

