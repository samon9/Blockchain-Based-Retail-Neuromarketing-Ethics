;; Retailer Verification Contract
;; Validates neuromarketing practitioners and their credentials

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_VERIFIED (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INVALID_CREDENTIALS (err u103))

;; Data structures
(define-map verified-retailers
  { retailer: principal }
  {
    verified: bool,
    verification-date: uint,
    credentials-hash: (buff 32),
    expiry-date: uint,
    verification-level: uint
  }
)

(define-map verification-requests
  { request-id: uint }
  {
    retailer: principal,
    credentials-hash: (buff 32),
    requested-at: uint,
    status: (string-ascii 20)
  }
)

(define-data-var next-request-id uint u1)

;; Public functions
(define-public (submit-verification-request (credentials-hash (buff 32)))
  (let ((request-id (var-get next-request-id)))
    (map-set verification-requests
      { request-id: request-id }
      {
        retailer: tx-sender,
        credentials-hash: credentials-hash,
        requested-at: block-height,
        status: "pending"
      }
    )
    (var-set next-request-id (+ request-id u1))
    (ok request-id)
  )
)

(define-public (verify-retailer (retailer principal) (credentials-hash (buff 32)) (verification-level uint) (validity-period uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? verified-retailers { retailer: retailer })) ERR_ALREADY_VERIFIED)
    (map-set verified-retailers
      { retailer: retailer }
      {
        verified: true,
        verification-date: block-height,
        credentials-hash: credentials-hash,
        expiry-date: (+ block-height validity-period),
        verification-level: verification-level
      }
    )
    (ok true)
  )
)

(define-public (revoke-verification (retailer principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? verified-retailers { retailer: retailer })) ERR_NOT_FOUND)
    (map-delete verified-retailers { retailer: retailer })
    (ok true)
  )
)

;; Read-only functions
(define-read-only (is-verified (retailer principal))
  (match (map-get? verified-retailers { retailer: retailer })
    verification-data (and
      (get verified verification-data)
      (> (get expiry-date verification-data) block-height)
    )
    false
  )
)

(define-read-only (get-verification-details (retailer principal))
  (map-get? verified-retailers { retailer: retailer })
)

(define-read-only (get-verification-request (request-id uint))
  (map-get? verification-requests { request-id: request-id })
)
