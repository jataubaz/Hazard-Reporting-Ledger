(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-company-not-found (err u101))
(define-constant err-report-not-found (err u102))
(define-constant err-already-verified (err u103))
(define-constant err-unauthorized (err u104))
(define-constant err-invalid-severity (err u105))
(define-constant err-already-exists (err u106))
(define-constant err-invalid-status (err u107))
(define-constant err-not-reporter (err u108))
(define-constant err-not-verifier (err u109))
(define-constant err-invalid-date (err u110))
(define-constant err-already-resolved (err u111))
(define-constant err-not-company (err u112))
(define-constant err-invalid-location (err u113))
(define-constant err-response-exists (err u114))
(define-constant err-no-response (err u115))
(define-constant err-not-escalatable (err u116))
(define-constant err-already-escalated (err u117))

(define-constant severity-critical u5)
(define-constant severity-high u4)
(define-constant severity-medium u3)
(define-constant severity-low u2)
(define-constant severity-minor u1)

(define-constant status-pending "pending")
(define-constant status-verified "verified")
(define-constant status-investigating "investigating")
(define-constant status-resolved "resolved")
(define-constant status-disputed "disputed")
(define-constant status-escalated "escalated")

(define-constant escalation-threshold-critical u144)
(define-constant escalation-threshold-high u288)
(define-constant escalation-threshold-medium u576)

(define-data-var report-id-nonce uint u0)
(define-data-var total-reports uint u0)
(define-data-var total-verified-reports uint u0)
(define-data-var total-resolved-reports uint u0)
(define-data-var critical-incidents-count uint u0)

(define-map companies principal {
    name: (string-ascii 100),
    industry: (string-ascii 50),
    registered-at: uint,
    total-reports: uint,
    critical-reports: uint,
    resolved-reports: uint,
    safety-score: uint,
    is-verified: bool
})

(define-map hazard-reports uint {
    reporter: principal,
    company: principal,
    incident-type: (string-ascii 50),
    description: (string-utf8 500),
    location: (string-ascii 200),
    severity: uint,
    reported-at: uint,
    incident-date: uint,
    status: (string-ascii 20),
    verified-by: (optional principal),
    verified-at: (optional uint),
    witnesses: (list 10 principal),
    evidence-hash: (optional (buff 32))
})

(define-map report-verifications uint {
    report-id: uint,
    verifier: principal,
    verification-date: uint,
    verification-notes: (string-utf8 200),
    authenticity-confirmed: bool
})

(define-map company-responses uint {
    report-id: uint,
    response-date: uint,
    response-text: (string-utf8 500),
    action-taken: (string-utf8 200),
    prevention-measures: (string-utf8 200),
    compensation-offered: (optional uint)
})

(define-map reporter-profiles principal {
    total-reports: uint,
    verified-reports: uint,
    credibility-score: uint,
    first-report-date: uint,
    last-report-date: uint,
    is-verified-reporter: bool
})

(define-map incident-categories (string-ascii 50) {
    total-incidents: uint,
    critical-count: uint,
    average-resolution-time: uint,
    most-recent-incident: uint
})

(define-map safety-inspectors principal {
    name: (string-ascii 100),
    organization: (string-ascii 100),
    verified-reports: uint,
    authorization-date: uint,
    is-active: bool
})

(define-map report-escalations uint {
    report-id: uint,
    escalated-at: uint,
    escalation-reason: (string-utf8 200),
    escalated-by: principal,
    severity-penalty: uint
})

(define-public (register-company (name (string-ascii 100)) (industry (string-ascii 50)))
    (let ((company-principal tx-sender))
        (asserts! (is-none (map-get? companies company-principal)) err-already-exists)
        (map-set companies company-principal {
            name: name,
            industry: industry,
            registered-at: stacks-block-height,
            total-reports: u0,
            critical-reports: u0,
            resolved-reports: u0,
            safety-score: u100,
            is-verified: false
        })
        (ok true)))

(define-public (verify-company (company principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (let ((company-data (unwrap! (map-get? companies company) err-company-not-found)))
            (map-set companies company
                (merge company-data { is-verified: true }))
            (ok true))))

(define-public (submit-hazard-report
    (company principal)
    (incident-type (string-ascii 50))
    (description (string-utf8 500))
    (location (string-ascii 200))
    (severity uint)
    (incident-date uint))
    (let 
        ((report-id (+ (var-get report-id-nonce) u1))
         (reporter tx-sender))
        
        (asserts! (is-some (map-get? companies company)) err-company-not-found)
        (asserts! (and (>= severity u1) (<= severity u5)) err-invalid-severity)
        (asserts! (<= incident-date stacks-block-height) err-invalid-date)
        
        (map-set hazard-reports report-id {
            reporter: reporter,
            company: company,
            incident-type: incident-type,
            description: description,
            location: location,
            severity: severity,
            reported-at: stacks-block-height,
            incident-date: incident-date,
            status: status-pending,
            verified-by: none,
            verified-at: none,
            witnesses: (list),
            evidence-hash: none
        })
        
        (var-set report-id-nonce report-id)
        (var-set total-reports (+ (var-get total-reports) u1))
        
        (if (is-eq severity severity-critical)
            (var-set critical-incidents-count (+ (var-get critical-incidents-count) u1))
            true)
        
        (update-company-metrics company severity false)
        (update-reporter-profile reporter)
        (update-incident-category incident-type severity)
        
        (ok report-id)))

(define-public (add-evidence-hash (report-id uint) (evidence-hash (buff 32)))
    (let ((report (unwrap! (map-get? hazard-reports report-id) err-report-not-found)))
        (asserts! (is-eq tx-sender (get reporter report)) err-not-reporter)
        (map-set hazard-reports report-id
            (merge report { evidence-hash: (some evidence-hash) }))
        (ok true)))

(define-public (add-witness (report-id uint) (witness principal))
    (let ((report (unwrap! (map-get? hazard-reports report-id) err-report-not-found)))
        (asserts! (is-eq tx-sender (get reporter report)) err-not-reporter)
        (let ((updated-witnesses (unwrap! (as-max-len? (append (get witnesses report) witness) u10) err-already-exists)))
            (map-set hazard-reports report-id
                (merge report { witnesses: updated-witnesses }))
            (ok true))))

(define-public (verify-report (report-id uint) (verification-notes (string-utf8 200)))
    (let 
        ((report (unwrap! (map-get? hazard-reports report-id) err-report-not-found))
         (verifier tx-sender))
        
        (asserts! (is-some (map-get? safety-inspectors verifier)) err-not-verifier)
        (asserts! (not (is-eq (get status report) status-verified)) err-already-verified)
        
        (map-set hazard-reports report-id
            (merge report {
                status: status-verified,
                verified-by: (some verifier),
                verified-at: (some stacks-block-height)
            }))
        
        (map-set report-verifications report-id {
            report-id: report-id,
            verifier: verifier,
            verification-date: stacks-block-height,
            verification-notes: verification-notes,
            authenticity-confirmed: true
        })
        
        (var-set total-verified-reports (+ (var-get total-verified-reports) u1))
        (update-inspector-metrics verifier)
        
        (ok true)))

(define-public (submit-company-response
    (report-id uint)
    (response-text (string-utf8 500))
    (action-taken (string-utf8 200))
    (prevention-measures (string-utf8 200)))
    (let ((report (unwrap! (map-get? hazard-reports report-id) err-report-not-found)))
        (asserts! (is-eq tx-sender (get company report)) err-not-company)
        (asserts! (is-none (map-get? company-responses report-id)) err-response-exists)
        
        (map-set company-responses report-id {
            report-id: report-id,
            response-date: stacks-block-height,
            response-text: response-text,
            action-taken: action-taken,
            prevention-measures: prevention-measures,
            compensation-offered: none
        })
        
        (map-set hazard-reports report-id
            (merge report { status: status-investigating }))
        
        (ok true)))

(define-public (resolve-incident (report-id uint) (compensation uint))
    (let 
        ((report (unwrap! (map-get? hazard-reports report-id) err-report-not-found))
         (response (unwrap! (map-get? company-responses report-id) err-no-response)))
        
        (asserts! (is-eq tx-sender (get company report)) err-not-company)
        (asserts! (not (is-eq (get status report) status-resolved)) err-already-resolved)
        
        (map-set hazard-reports report-id
            (merge report { status: status-resolved }))
        
        (map-set company-responses report-id
            (merge response { compensation-offered: (some compensation) }))
        
        (var-set total-resolved-reports (+ (var-get total-resolved-reports) u1))
        (update-company-metrics (get company report) (get severity report) true)
        
        (ok true)))

(define-public (authorize-inspector (inspector principal) (name (string-ascii 100)) (organization (string-ascii 100)))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set safety-inspectors inspector {
            name: name,
            organization: organization,
            verified-reports: u0,
            authorization-date: stacks-block-height,
            is-active: true
        })
        (ok true)))

(define-public (dispute-report (report-id uint))
    (let ((report (unwrap! (map-get? hazard-reports report-id) err-report-not-found)))
        (asserts! (is-eq tx-sender (get company report)) err-not-company)
        (map-set hazard-reports report-id
            (merge report { status: status-disputed }))
        (ok true)))

(define-public (escalate-report (report-id uint) (escalation-reason (string-utf8 200)))
    (let 
        ((report (unwrap! (map-get? hazard-reports report-id) err-report-not-found))
         (time-elapsed (- stacks-block-height (get reported-at report)))
         (report-severity (get severity report))
         (report-status (get status report))
         (escalator tx-sender))
        
        (asserts! (is-none (map-get? report-escalations report-id)) err-already-escalated)
        (asserts! (or (is-eq report-status status-pending) 
                      (is-eq report-status status-verified)
                      (is-eq report-status status-investigating)) err-not-escalatable)
        (asserts! (or (is-eq report-status status-resolved)
                      (is-eq report-status status-disputed)
                      (not (is-eq report-status status-escalated))) err-already-resolved)
        
        (asserts! (or 
            (and (is-eq report-severity severity-critical) (>= time-elapsed escalation-threshold-critical))
            (and (is-eq report-severity severity-high) (>= time-elapsed escalation-threshold-high))
            (and (is-eq report-severity severity-medium) (>= time-elapsed escalation-threshold-medium))) 
            err-not-escalatable)
        
        (let ((penalty-amount (* report-severity u5)))
            (map-set report-escalations report-id {
                report-id: report-id,
                escalated-at: stacks-block-height,
                escalation-reason: escalation-reason,
                escalated-by: escalator,
                severity-penalty: penalty-amount
            })
            
            (map-set hazard-reports report-id
                (merge report { status: status-escalated }))
            
            (match (map-get? companies (get company report))
                company-data
                (map-set companies (get company report)
                    (merge company-data {
                        safety-score: (if (>= (get safety-score company-data) penalty-amount)
                                        (- (get safety-score company-data) penalty-amount)
                                        u0)
                    }))
                true)
            
            (ok true))))

(define-private (update-company-metrics (company principal) (severity uint) (resolved bool))
    (match (map-get? companies company)
        company-data 
        (map-set companies company
            (if resolved
                (merge company-data {
                    resolved-reports: (+ (get resolved-reports company-data) u1),
                    safety-score: (+ (get safety-score company-data) u5)
                })
                (merge company-data {
                    total-reports: (+ (get total-reports company-data) u1),
                    critical-reports: (if (is-eq severity severity-critical)
                                        (+ (get critical-reports company-data) u1)
                                        (get critical-reports company-data)),
                    safety-score: (if (>= (get safety-score company-data) (* severity u2))
                                    (- (get safety-score company-data) (* severity u2))
                                    u0)
                })))
        true))

(define-private (update-reporter-profile (reporter principal))
    (let ((current-profile (default-to
            { total-reports: u0, verified-reports: u0, credibility-score: u100, 
              first-report-date: stacks-block-height, last-report-date: stacks-block-height,
              is-verified-reporter: false }
            (map-get? reporter-profiles reporter))))
        (map-set reporter-profiles reporter
            (merge current-profile {
                total-reports: (+ (get total-reports current-profile) u1),
                last-report-date: stacks-block-height,
                credibility-score: (+ (get credibility-score current-profile) u10)
            }))))

(define-private (update-incident-category (incident-type (string-ascii 50)) (severity uint))
    (let ((current-stats (default-to
            { total-incidents: u0, critical-count: u0, average-resolution-time: u0, most-recent-incident: u0 }
            (map-get? incident-categories incident-type))))
        (map-set incident-categories incident-type
            (merge current-stats {
                total-incidents: (+ (get total-incidents current-stats) u1),
                critical-count: (if (is-eq severity severity-critical)
                                  (+ (get critical-count current-stats) u1)
                                  (get critical-count current-stats)),
                most-recent-incident: stacks-block-height
            }))))

(define-private (update-inspector-metrics (inspector principal))
    (match (map-get? safety-inspectors inspector)
        inspector-data
        (map-set safety-inspectors inspector
            (merge inspector-data {
                verified-reports: (+ (get verified-reports inspector-data) u1)
            }))
        true))

(define-read-only (get-report (report-id uint))
    (map-get? hazard-reports report-id))

(define-read-only (get-company-profile (company principal))
    (map-get? companies company))

(define-read-only (get-company-response (report-id uint))
    (map-get? company-responses report-id))

(define-read-only (get-reporter-profile (reporter principal))
    (map-get? reporter-profiles reporter))

(define-read-only (get-platform-statistics)
    (ok {
        total-reports: (var-get total-reports),
        verified-reports: (var-get total-verified-reports),
        resolved-reports: (var-get total-resolved-reports),
        critical-incidents: (var-get critical-incidents-count)
    }))

(define-read-only (get-incident-category-stats (incident-type (string-ascii 50)))
    (map-get? incident-categories incident-type))

(define-read-only (get-inspector-profile (inspector principal))
    (map-get? safety-inspectors inspector))

(define-read-only (calculate-company-risk-score (company principal))
    (match (map-get? companies company)
        company-data
        (let ((risk-factor (+ (* (get critical-reports company-data) u10)
                              (* (get total-reports company-data) u2))))
            (ok (if (> (get resolved-reports company-data) u0)
                   (/ risk-factor (get resolved-reports company-data))
                   risk-factor)))
        (err err-company-not-found)))

(define-read-only (is-report-escalatable (report-id uint))
    (match (map-get? hazard-reports report-id)
        report
        (let 
            ((time-elapsed (- stacks-block-height (get reported-at report)))
             (report-severity (get severity report))
             (report-status (get status report))
             (already-escalated (is-some (map-get? report-escalations report-id))))
            
            (ok {
                escalatable: (and 
                    (not already-escalated)
                    (or (is-eq report-status status-pending) 
                        (is-eq report-status status-verified)
                        (is-eq report-status status-investigating))
                    (or 
                        (and (is-eq report-severity severity-critical) (>= time-elapsed escalation-threshold-critical))
                        (and (is-eq report-severity severity-high) (>= time-elapsed escalation-threshold-high))
                        (and (is-eq report-severity severity-medium) (>= time-elapsed escalation-threshold-medium)))),
                time-elapsed: time-elapsed,
                required-threshold: (if (is-eq report-severity severity-critical)
                                       escalation-threshold-critical
                                       (if (is-eq report-severity severity-high)
                                          escalation-threshold-high
                                          escalation-threshold-medium))
            }))
        (err err-report-not-found)))

(define-read-only (get-escalation-details (report-id uint))
    (map-get? report-escalations report-id))

