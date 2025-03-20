;; Vaccine Tracking Smart Contract

;; Contract Owner Management
(define-data-var contract-administrator principal tx-sender)

;; Error Codes
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-INVALID-BATCH-DATA (err u101))
(define-constant ERR-BATCH-ALREADY-EXISTS (err u102))
(define-constant ERR-BATCH-NOT-FOUND (err u103))
(define-constant ERR-VACCINE-QUANTITY-INSUFFICIENT (err u104))
(define-constant ERR-PATIENT-ID-INVALID (err u105))
(define-constant ERR-PATIENT-PREVIOUSLY-VACCINATED (err u106))
(define-constant ERR-TEMPERATURE-RANGE-VIOLATION (err u107))
(define-constant ERR-BATCH-EXPIRATION-PASSED (err u108))
(define-constant ERR-VACCINATION-LOCATION-INVALID (err u109))
(define-constant ERR-DOSE-MAXIMUM-REACHED (err u110))
(define-constant ERR-DOSE-INTERVAL-INSUFFICIENT (err u111))
(define-constant ERR-ADMIN-FUNCTION-ONLY (err u112))
(define-constant ERR-DATA-VALIDATION-FAILED (err u113))
(define-constant ERR-EXPIRY-DATE-INVALID (err u114))
(define-constant ERR-STORAGE-CAPACITY-INVALID (err u115))
(define-constant ERR-INVALID-PRINCIPAL (err u116))

;; System Constants
(define-constant min-storage-temp (- 70))
(define-constant max-storage-temp 8)
(define-constant min-days-between-doses u21) ;; 21 days minimum between doses
(define-constant max-doses-per-patient u4)
(define-constant min-string-length u1)
(define-constant current-block-height block-height)

;; Data Structures
(define-map vaccine-inventory
    { batch-id: (string-ascii 32) }
    {
        manufacturer: (string-ascii 50),
        product-name: (string-ascii 50),
        production-date: uint,
        expiration-date: uint,
        remaining-doses: uint,
        required-storage-temp: int,
        current-status: (string-ascii 20),
        temp-breach-incidents: uint,
        storage-location: (string-ascii 100),
        batch-comments: (string-ascii 500)
    }
)

(define-map patient-records
    { patient-id: (string-ascii 32) }
    {
        vaccination-events: (list 10 {
            batch-id: (string-ascii 32),
            injection-date: uint,
            vaccine-product: (string-ascii 50),
            dose-number: uint,
            administering-provider: principal,
            injection-location: (string-ascii 100),
            follow-up-date: (optional uint)
        }),
        total-doses-received: uint,
        adverse-reactions: (list 5 (string-ascii 200)),
        exemption-details: (optional (string-ascii 200))
    }
)

(define-map authorized-providers 
    principal 
    {
        staff-role: (string-ascii 20),
        facility-name: (string-ascii 100),
        authorization-expiry: uint
    }
)

(define-map storage-facilities
    (string-ascii 100)
    {
        physical-address: (string-ascii 200),
        dose-capacity: uint,
        current-stock: uint,
        temperature-log: (list 100 {
            timestamp: uint,
            temperature: int
        })
    }
)

;; Private Helper Functions
(define-private (is-contract-admin)
    (is-eq tx-sender (var-get contract-administrator))
)

;; String Validation Functions
(define-private (validate-text-32 (input (string-ascii 32)))
    (> (len input) min-string-length)
)

(define-private (validate-text-20 (input (string-ascii 20)))
    (> (len input) min-string-length)
)

(define-private (validate-text-50 (input (string-ascii 50)))
    (> (len input) min-string-length)
)

(define-private (validate-text-100 (input (string-ascii 100)))
    (> (len input) min-string-length)
)

(define-private (validate-text-200 (input (string-ascii 200)))
    (> (len input) min-string-length)
)

(define-private (is-future-date (date uint))
    (> date current-block-height)
)

(define-private (is-valid-capacity (capacity uint))
    (> capacity u0)
)

;; Principal Validation
(define-private (is-valid-principal (user-principal principal))
    (not (is-eq user-principal tx-sender))
)

;; Read-only Functions - Contract Information
(define-read-only (get-contract-admin)
    (ok (var-get contract-administrator))
)

(define-read-only (is-provider-valid (provider-address principal))
    (match (map-get? authorized-providers provider-address)
        provider-data (>= (get authorization-expiry provider-data) current-block-height)
        false
    )
)

(define-read-only (get-batch-details (batch-id (string-ascii 32)))
    (map-get? vaccine-inventory {batch-id: batch-id})
)

(define-read-only (get-patient-history (patient-id (string-ascii 32)))
    (map-get? patient-records {patient-id: patient-id})
)

(define-read-only (get-facility-details (facility-id (string-ascii 100)))
    (map-get? storage-facilities facility-id)
)

(define-read-only (is-batch-valid (batch-id (string-ascii 32)))
    (match (map-get? vaccine-inventory {batch-id: batch-id})
        batch-data (and
            (is-eq (get current-status batch-data) "active")
            (> (get remaining-doses batch-data) u0)
            (<= current-block-height (get expiration-date batch-data))
            (<= (get temp-breach-incidents batch-data) u2))
        false
    )
)

;; Administrative Functions
(define-public (transfer-admin-rights (new-admin principal))
    (begin
        (asserts! (is-contract-admin) ERR-ADMIN-FUNCTION-ONLY)
        (asserts! (is-valid-principal new-admin) ERR-INVALID-PRINCIPAL)
        (ok (var-set contract-administrator new-admin))
    )
)

(define-public (add-healthcare-provider 
    (provider-address principal)
    (role (string-ascii 20))
    (facility (string-ascii 100))
    (credential-expiry uint))
    (begin
        (asserts! (is-contract-admin) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (validate-text-20 role) ERR-DATA-VALIDATION-FAILED)
        (asserts! (validate-text-100 facility) ERR-DATA-VALIDATION-FAILED)
        (asserts! (is-future-date credential-expiry) ERR-EXPIRY-DATE-INVALID)
        (asserts! (is-valid-principal provider-address) ERR-INVALID-PRINCIPAL)
        (ok (map-set authorized-providers 
            provider-address 
            {
                staff-role: role,
                facility-name: facility,
                authorization-expiry: credential-expiry
            }))
    )
)

(define-public (add-storage-location
    (facility-id (string-ascii 100))
    (physical-address (string-ascii 200))
    (dose-capacity uint))
    (begin
        (asserts! (is-contract-admin) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (validate-text-100 facility-id) ERR-DATA-VALIDATION-FAILED)
        (asserts! (validate-text-200 physical-address) ERR-DATA-VALIDATION-FAILED)
        (asserts! (is-valid-capacity dose-capacity) ERR-STORAGE-CAPACITY-INVALID)
        (ok (map-set storage-facilities
            facility-id
            {
                physical-address: physical-address,
                dose-capacity: dose-capacity,
                current-stock: u0,
                temperature-log: (list)
            }))
    )
)

;; Vaccine Management Functions
(define-public (add-vaccine-batch 
    (batch-id (string-ascii 32))
    (manufacturer (string-ascii 50))
    (product-name (string-ascii 50))
    (production-date uint)
    (expiration-date uint)
    (initial-doses uint)
    (storage-temp int)
    (facility-id (string-ascii 100)))
    (begin
        (asserts! (is-provider-valid tx-sender) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (validate-text-32 batch-id) ERR-DATA-VALIDATION-FAILED)
        (asserts! (validate-text-50 manufacturer) ERR-DATA-VALIDATION-FAILED)
        (asserts! (validate-text-50 product-name) ERR-DATA-VALIDATION-FAILED)
        (asserts! (validate-text-100 facility-id) ERR-DATA-VALIDATION-FAILED)
        (asserts! (is-none (map-get? vaccine-inventory {batch-id: batch-id})) ERR-BATCH-ALREADY-EXISTS)
        (asserts! (is-valid-capacity initial-doses) ERR-INVALID-BATCH-DATA)
        (asserts! (is-future-date expiration-date) ERR-EXPIRY-DATE-INVALID)
        (asserts! (> expiration-date production-date) ERR-INVALID-BATCH-DATA)
        (asserts! (and (>= storage-temp min-storage-temp) 
                      (<= storage-temp max-storage-temp)) 
                 ERR-TEMPERATURE-RANGE-VIOLATION)
        
        (ok (map-set vaccine-inventory 
            {batch-id: batch-id}
            {
                manufacturer: manufacturer,
                product-name: product-name,
                production-date: production-date,
                expiration-date: expiration-date,
                remaining-doses: initial-doses,
                required-storage-temp: storage-temp,
                current-status: "active",
                temp-breach-incidents: u0,
                storage-location: facility-id,
                batch-comments: ""
            }))
    )
)

(define-public (update-batch-status
    (batch-id (string-ascii 32))
    (new-status (string-ascii 20)))
    (begin
        (asserts! (is-provider-valid tx-sender) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (validate-text-32 batch-id) ERR-DATA-VALIDATION-FAILED)
        (asserts! (validate-text-20 new-status) ERR-DATA-VALIDATION-FAILED)
        (match (map-get? vaccine-inventory {batch-id: batch-id})
            batch-data (ok (map-set vaccine-inventory 
                {batch-id: batch-id}
                (merge batch-data {current-status: new-status})))
            ERR-BATCH-NOT-FOUND
        )
    )
)

(define-public (log-temperature-breach
    (batch-id (string-ascii 32))
    (breach-temp int))
    (begin
        (asserts! (is-provider-valid tx-sender) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (validate-text-32 batch-id) ERR-DATA-VALIDATION-FAILED)
        (match (map-get? vaccine-inventory {batch-id: batch-id})
            batch-data (ok (map-set vaccine-inventory 
                {batch-id: batch-id}
                (merge batch-data {
                    temp-breach-incidents: (+ (get temp-breach-incidents batch-data) u1),
                    current-status: (if (> (get temp-breach-incidents batch-data) u2) 
                                    "compromised" 
                                    (get current-status batch-data))
                })))
            ERR-BATCH-NOT-FOUND
        )
    )
)

;; Patient Vaccination Functions
(define-public (register-vaccination
    (patient-id (string-ascii 32))
    (batch-id (string-ascii 32))
    (clinic-location (string-ascii 100)))
    (begin
        (asserts! (is-provider-valid tx-sender) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (validate-text-32 patient-id) ERR-PATIENT-ID-INVALID)
        (asserts! (validate-text-32 batch-id) ERR-DATA-VALIDATION-FAILED)
        (asserts! (validate-text-100 clinic-location) ERR-VACCINATION-LOCATION-INVALID)
        
        (match (map-get? vaccine-inventory {batch-id: batch-id})
            batch-data (begin
                (asserts! (> (get remaining-doses batch-data) u0) ERR-VACCINE-QUANTITY-INSUFFICIENT)
                (asserts! (is-eq (get current-status batch-data) "active") ERR-INVALID-BATCH-DATA)
                (asserts! (<= current-block-height (get expiration-date batch-data)) ERR-BATCH-EXPIRATION-PASSED)
                
                (match (map-get? patient-records {patient-id: patient-id})
                    patient-data (begin
                        (asserts! (< (get total-doses-received patient-data) max-doses-per-patient) 
                                ERR-DOSE-MAXIMUM-REACHED)
                        (let ((new-dose-number (+ (get total-doses-received patient-data) u1)))
                            (if (> new-dose-number u1)
                                (asserts! (>= (- current-block-height 
                                    (get injection-date (unwrap-panic (element-at 
                                        (get vaccination-events patient-data) 
                                        (- new-dose-number u2))))) 
                                    min-days-between-doses)
                                    ERR-DOSE-INTERVAL-INSUFFICIENT)
                                true
                            )
                            
                            (ok (map-set patient-records
                                {patient-id: patient-id}
                                {
                                    vaccination-events: (unwrap-panic (as-max-len? 
                                        (append (get vaccination-events patient-data)
                                            {
                                                batch-id: batch-id,
                                                injection-date: current-block-height,
                                                vaccine-product: (get product-name batch-data),
                                                dose-number: new-dose-number,
                                                administering-provider: tx-sender,
                                                injection-location: clinic-location,
                                                follow-up-date: (some (+ current-block-height min-days-between-doses))
                                            }
                                        ) u10)),
                                    total-doses-received: new-dose-number,
                                    adverse-reactions: (get adverse-reactions patient-data),
                                    exemption-details: (get exemption-details patient-data)
                                }))))
                    ;; First dose for patient
                    (ok (map-set patient-records
                        {patient-id: patient-id}
                        {
                            vaccination-events: (list 
                                {
                                    batch-id: batch-id,
                                    injection-date: current-block-height,
                                    vaccine-product: (get product-name batch-data),
                                    dose-number: u1,
                                    administering-provider: tx-sender,
                                    injection-location: clinic-location,
                                    follow-up-date: (some (+ current-block-height min-days-between-doses))
                                }),
                            total-doses-received: u1,
                            adverse-reactions: (list),
                            exemption-details: none
                        })))
            )
            ERR-BATCH-NOT-FOUND
        )
    )
)