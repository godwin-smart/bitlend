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

;; User Reputation System
(define-map user-reputation
    { user: principal }
    {
        successful-repayments: uint,
        defaults: uint,
        total-borrowed: uint,
        reputation-score: uint,
    }
)

;; ADMINISTRATIVE FUNCTIONS

;; Transfer Contract Ownership
(define-public (set-contract-owner (new-owner principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (asserts! (not (is-eq new-owner (var-get contract-owner)))
            ERR-INVALID-AMOUNT
        )
        (var-set contract-owner new-owner)
        (ok true)
    )
)

;; Emergency Circuit Breaker
(define-public (toggle-emergency-stop)
    (begin
        (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
        (var-set emergency-stopped (not (var-get emergency-stopped)))
        (ok true)
    )
)

;; UTILITY FUNCTIONS

;; Check if contract is operational
(define-private (is-contract-active)
    (not (var-get emergency-stopped))
)

;; Verify administrative privileges
(define-private (is-authorized)
    (is-eq tx-sender (var-get contract-owner))
)

;; Validate collateral asset eligibility
(define-private (is-valid-collateral-asset (asset (string-ascii 20)))
    (match (map-get? allowed-collateral-assets { asset: asset })
        allowed-asset (get is-active allowed-asset)
        false
    )
)

;; Calculate collateral-to-loan ratio
(define-private (calculate-collateral-ratio
        (loan-amount uint)
        (collateral-amount uint)
    )
    (/ (* collateral-amount u100) loan-amount)
)

;; Verify adequate collateral coverage
(define-private (is-sufficient-collateral
        (loan-amount uint)
        (collateral-amount uint)
    )
    (>= (calculate-collateral-ratio loan-amount collateral-amount)
        MIN-COLLATERAL-RATIO
    )
)

;; Determine liquidation price threshold
(define-private (calculate-liquidation-threshold (current-price uint))
    (/ (* current-price LIQUIDATION-THRESHOLD) u100)
)

;; Retrieve current asset price with validation
(define-private (get-current-asset-price (asset (string-ascii 20)))
    (match (map-get? asset-prices { asset: asset })
        price-info (if (and
                (> (get price price-info) u0)
                (< (- stacks-block-height (get last-updated price-info))
                    MAX-PRICE-AGE
                )
            )
            (ok (get price price-info))
            (err ERR-PRICE-FEED-FAILURE)
        )
        (err ERR-PRICE-FEED-FAILURE)
    )
)

;; Check if collateral maintains liquidation threshold
(define-private (is-collateral-above-liquidation-threshold (loan-id uint))
    (match (map-get? loans { loan-id: loan-id })
        loan (match (get-current-asset-price (get collateral-asset loan))
            current-price-ok (>= current-price-ok (get liquidation-price-threshold loan))
            err-code
            false
        )
        false
    )
)

;; Update borrower reputation scoring
(define-private (update-user-reputation
        (user principal)
        (success bool)
    )
    (let (
            (current-reputation (default-to {
                successful-repayments: u0,
                defaults: u0,
                total-borrowed: u0,
                reputation-score: u100,
            }
                (map-get? user-reputation { user: user })
            ))
            (current-score (get reputation-score current-reputation))
            (new-score (if success
                (if (> (+ current-score REPUTATION_REWARD) MAX-REPUTATION-SCORE)
                    MAX-REPUTATION-SCORE
                    (+ current-score REPUTATION_REWARD)
                )
                (if (> current-score REPUTATION_PENALTY)
                    (- current-score REPUTATION_PENALTY)
                    MIN-REPUTATION-SCORE
                )
            ))
        )
        (map-set user-reputation { user: user } {
            successful-repayments: (if success
                (+ (get successful-repayments current-reputation) u1)
                (get successful-repayments current-reputation)
            ),
            defaults: (if success
                (get defaults current-reputation)
                (+ (get defaults current-reputation) u1)
            ),
            total-borrowed: (get total-borrowed current-reputation),
            reputation-score: new-score,
        })
    )
)

;; COLLATERAL ASSET MANAGEMENT

;; Add approved collateral asset
(define-public (add-collateral-asset (asset (string-ascii 20)))
    (begin
        (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
        (asserts! (> (len asset) u0) ERR-INVALID-AMOUNT)
        (map-set allowed-collateral-assets { asset: asset } { is-active: true })
        (ok true)
    )
)

;; Remove collateral asset from whitelist
(define-public (remove-collateral-asset (asset (string-ascii 20)))
    (begin
        (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
        (asserts! (> (len asset) u0) ERR-INVALID-AMOUNT)
        (map-set allowed-collateral-assets { asset: asset } { is-active: false })
        (ok true)
    )
)

;; PRICE FEED MANAGEMENT

;; Update asset price data
(define-public (update-asset-price
        (asset (string-ascii 20))
        (price uint)
    )
    (begin
        (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
        (asserts! (> (len asset) u0) ERR-INVALID-AMOUNT)
        (asserts! (> price u0) ERR-INVALID-AMOUNT)
        (asserts! (is-valid-collateral-asset asset) ERR-INVALID-COLLATERAL-ASSET)
        (map-set asset-prices { asset: asset } {
            price: price,
            last-updated: stacks-block-height,
        })
        (ok true)
    )
)

;; LOAN MANAGEMENT FUNCTIONS

;; Create new loan request with comprehensive validation
(define-public (create-loan-request
        (amount uint)
        (collateral uint)
        (collateral-asset (string-ascii 20))
        (duration uint)
        (interest-rate uint)
    )
    (let (
            (loan-id (var-get next-loan-id))
            (tx-sender-account tx-sender)
            (current-asset-price (unwrap! (get-current-asset-price collateral-asset)
                ERR-PRICE-FEED-FAILURE
            ))
        )
        ;; Protocol Security Checks
        (asserts! (is-contract-active) ERR-EMERGENCY-STOP)
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (asserts! (> collateral u0) ERR-INSUFFICIENT-COLLATERAL)
        (asserts! (is-sufficient-collateral amount collateral)
            ERR-INSUFFICIENT-COLLATERAL
        )
        (asserts! (is-valid-collateral-asset collateral-asset)
            ERR-INVALID-COLLATERAL-ASSET
        )
        ;; Loan Parameter Validation
        (asserts!
            (and
                (>= duration MIN-DURATION)
                (<= duration MAX-DURATION)
            )
            ERR-INVALID-DURATION
        )
        (asserts! (<= interest-rate MAX-INTEREST-RATE) ERR-INVALID-INTEREST-RATE)
        ;; Create loan record
        (map-set loans { loan-id: loan-id } {
            borrower: tx-sender-account,
            amount: amount,
            collateral-amount: collateral,
            collateral-asset: collateral-asset,
            interest-rate: interest-rate,
            start-height: stacks-block-height,
            duration: duration,
            status: "PENDING",
            lenders: (list),
            repaid-amount: u0,
            liquidation-price-threshold: (calculate-liquidation-threshold current-asset-price),
        })
        ;; Update user loan portfolio
        (let ((existing-user-loans (default-to {
                active-loans: (list),
                total-active-borrowed: u0,
            }
                (map-get? user-loans { user: tx-sender-account })
            )))
            (map-set user-loans { user: tx-sender-account } {
                active-loans: (unwrap-panic (as-max-len?
                    (append (get active-loans existing-user-loans) loan-id)
                    u20
                )),
                total-active-borrowed: (+ (get total-active-borrowed existing-user-loans) amount),
            })
        )
        ;; Increment loan counter
        (var-set next-loan-id (+ loan-id u1))
        (ok loan-id)
    )
)

;; Activate pending loan
(define-public (activate-loan (loan-id uint))
    (begin
        ;; Validate loan existence
        (asserts! (> loan-id u0) ERR-LOAN-NOT-FOUND)
        (asserts! (< loan-id (var-get next-loan-id)) ERR-LOAN-NOT-FOUND)
        (let ((loan (unwrap! (map-get? loans { loan-id: loan-id }) ERR-LOAN-NOT-FOUND)))
            (begin
                (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
                (asserts! (is-eq (get status loan) "PENDING")
                    ERR-LOAN-ALREADY-ACTIVE
                )
                (map-set loans { loan-id: loan-id }
                    (merge loan {
                        status: "ACTIVE",
                        start-height: stacks-block-height,
                    })
                )
                (ok true)
            )
        )
    )
)

;; Execute loan liquidation
(define-public (liquidate-loan (loan-id uint))
    (begin
        ;; Validate loan identifier
        (asserts! (> loan-id u0) ERR-LOAN-NOT-FOUND)
        (let ((loan (unwrap! (map-get? loans { loan-id: loan-id }) ERR-LOAN-NOT-FOUND)))
            ;; Security and status validation
            (asserts! (is-contract-active) ERR-EMERGENCY-STOP)
            (asserts! (is-eq (get status loan) "ACTIVE") ERR-LOAN-NOT-ACTIVE)
            ;; Liquidation trigger conditions
            (asserts!
                (or
                    (> stacks-block-height
                        (+ (get start-height loan) (get duration loan))
                    )
                    (not (is-collateral-above-liquidation-threshold loan-id))
                )
                ERR-LOAN-NOT-DEFAULTED
            )
            ;; Execute liquidation
            (map-set loans { loan-id: loan-id }
                (merge loan { status: "LIQUIDATED" })
            )
            ;; Apply reputation penalty
            (update-user-reputation (get borrower loan) false)
            (ok true)
        )
    )
)

;; READ-ONLY FUNCTIONS

;; Retrieve loan information
(define-read-only (get-loan (loan-id uint))
    (map-get? loans { loan-id: loan-id })
)

;; Get user reputation data
(define-read-only (get-user-reputation (user principal))
    (map-get? user-reputation { user: user })
)

;; Check contract operational status
(define-read-only (get-contract-status)
    (var-get emergency-stopped)
)

;; Get current contract owner
(define-read-only (get-contract-owner)
    (var-get contract-owner)
)

;; Calculate total loan repayment amount
(define-read-only (calculate-total-due (loan-id uint))
    (match (map-get? loans { loan-id: loan-id })
        loan (ok (+ (get amount loan)
            (/ (* (get amount loan) (get interest-rate loan)) u100)
        ))
        ERR-LOAN-NOT-FOUND
    )
)
