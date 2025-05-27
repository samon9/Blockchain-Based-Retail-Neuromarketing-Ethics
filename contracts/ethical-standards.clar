;; Ethical Standards Contract
;; Records and manages neuromarketing ethical guidelines

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_STANDARD_EXISTS (err u201))
(define-constant ERR_STANDARD_NOT_FOUND (err u202))

;; Data structures
(define-map ethical-standards
  { standard-id: uint }
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    category: (string-ascii 50),
    severity-level: uint,
    created-at: uint,
    updated-at: uint,
    active: bool
  }
)

(define-map standard-violations
  { violation-id: uint }
  {
    retailer: principal,
    standard-id: uint,
    description: (string-ascii 300),
    reported-at: uint,
    severity: uint,
    resolved: bool
  }
)

(define-data-var next-standard-id uint u1)
(define-data-var next-violation-id uint u1)

;; Public functions
(define-public (create-ethical-standard
  (title (string-ascii 100))
  (description (string-ascii 500))
  (category (string-ascii 50))
  (severity-level uint)
)
  (let ((standard-id (var-get next-standard-id)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set ethical-standards
      { standard-id: standard-id }
      {
        title: title,
        description: description,
        category: category,
        severity-level: severity-level,
        created-at: block-height,
        updated-at: block-height,
        active: true
      }
    )
    (var-set next-standard-id (+ standard-id u1))
    (ok standard-id)
  )
)

(define-public (update-ethical-standard
  (standard-id uint)
  (title (string-ascii 100))
  (description (string-ascii 500))
  (severity-level uint)
)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? ethical-standards { standard-id: standard-id })) ERR_STANDARD_NOT_FOUND)
    (map-set ethical-standards
      { standard-id: standard-id }
      (merge
        (unwrap-panic (map-get? ethical-standards { standard-id: standard-id }))
        {
          title: title,
          description: description,
          severity-level: severity-level,
          updated-at: block-height
        }
      )
    )
    (ok true)
  )
)

(define-public (report-violation
  (retailer principal)
  (standard-id uint)
  (description (string-ascii 300))
  (severity uint)
)
  (let ((violation-id (var-get next-violation-id)))
    (asserts! (is-some (map-get? ethical-standards { standard-id: standard-id })) ERR_STANDARD_NOT_FOUND)
    (map-set standard-violations
      { violation-id: violation-id }
      {
        retailer: retailer,
        standard-id: standard-id,
        description: description,
        reported-at: block-height,
        severity: severity,
        resolved: false
      }
    )
    (var-set next-violation-id (+ violation-id u1))
    (ok violation-id)
  )
)

;; Read-only functions
(define-read-only (get-ethical-standard (standard-id uint))
  (map-get? ethical-standards { standard-id: standard-id })
)

(define-read-only (get-violation (violation-id uint))
  (map-get? standard-violations { violation-id: violation-id })
)

(define-read-only (is-standard-active (standard-id uint))
  (match (map-get? ethical-standards { standard-id: standard-id })
    standard-data (get active standard-data)
    false
  )
)
