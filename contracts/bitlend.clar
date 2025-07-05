;; BitLend Protocol
;; Summary: A comprehensive decentralized lending protocol built on Bitcoin Layer 2
;;
;; Description: 
;; BitLend Protocol revolutionizes peer-to-peer lending by leveraging Bitcoin's 
;; security through Stacks Layer 2 technology. Our protocol enables users to 
;; create collateral-backed loans with dynamic risk management, automated 
;; liquidation mechanisms, and reputation-based lending scores. Built with 
;; enterprise-grade security features including emergency circuit breakers, 
;; multi-asset collateral support, and real-time price feed integration.
;;
;; Key Features:
;; - Multi-asset collateral support with whitelisting
;; - Dynamic liquidation thresholds based on market volatility
;; - Reputation scoring system for borrower assessment
;; - Emergency stop functionality for protocol security
;; - Automated interest calculation and repayment tracking
;; - Real-time price feed integration for accurate valuations

;; ERROR CONSTANTS
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-INVALID-AMOUNT (err u1001))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u1002))
(define-constant ERR-LOAN-NOT-FOUND (err u1003))
(define-constant ERR-LOAN-ALREADY-ACTIVE (err u1004))
(define-constant ERR-LOAN-NOT-ACTIVE (err u1005))
(define-constant ERR-LOAN-NOT-DEFAULTED (err u1006))
(define-constant ERR-INVALID-LIQUIDATION (err u1007))
(define-constant ERR-INVALID-REPAYMENT (err u1008))
(define-constant ERR-INVALID-DURATION (err u1009))
(define-constant ERR-INVALID-INTEREST-RATE (err u1010))
(define-constant ERR-EMERGENCY-STOP (err u1011))
(define-constant ERR-PRICE-FEED-FAILURE (err u1012))
(define-constant ERR-INVALID-COLLATERAL-ASSET (err u1013))
(define-constant tx-sender-zero (as-contract tx-sender))

;; PROTOCOL PARAMETERS
(define-constant MIN-COLLATERAL-RATIO u200) ;; 200% minimum collateral ratio
(define-constant MAX-INTEREST-RATE u5000) ;; 50% maximum annual interest rate
(define-constant MIN-DURATION u1440) ;; 1 day minimum loan duration
(define-constant MAX-DURATION u525600) ;; 1 year maximum loan duration
(define-constant LIQUIDATION-THRESHOLD u80) ;; 80% collateral value threshold
(define-constant MAX-PRICE-AGE u1440) ;; 1 day maximum price data age
(define-constant MIN-REPUTATION-SCORE u0) ;; Minimum reputation score
(define-constant MAX-REPUTATION-SCORE u200) ;; Maximum reputation score
(define-constant REPUTATION_PENALTY u20) ;; Reputation penalty for defaults
(define-constant REPUTATION_REWARD u10) ;; Reputation reward for successful repayments

;; STATE VARIABLES
(define-data-var emergency-stopped bool false)
(define-data-var contract-owner principal tx-sender)
(define-data-var next-loan-id uint u1)

;; DATA MAPS

;; Collateral Asset Whitelist
(define-map allowed-collateral-assets
    { asset: (string-ascii 20) }
    { is-active: bool }
)

;; Price Feed Data Storage
(define-map asset-prices
    { asset: (string-ascii 20) }
    {
        price: uint,
        last-updated: uint,
    }
)

;; Loan Registry
(define-map loans
    { loan-id: uint }
    {
        borrower: principal,
        amount: uint,
        collateral-amount: uint,
        collateral-asset: (string-ascii 20),
        interest-rate: uint,
        start-height: uint,
        duration: uint,
        status: (string-ascii 20),
        lenders: (list 20 principal),
        repaid-amount: uint,
        liquidation-price-threshold: uint,
    }
)

;; User Loan Portfolio Tracking
(define-map user-loans
    { user: principal }
    {
        active-loans: (list 20 uint),
        total-active-borrowed: uint,
    }
)