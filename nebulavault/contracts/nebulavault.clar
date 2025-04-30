;; NebulaVault: Celestial Treasury Management Protocol (NVP)
;; A system for managing cosmic funding allocations with constellation-based distributions

;; Constants
(define-constant NEBULA_KEEPER tx-sender)
(define-constant STARDUST_MINIMUM u100)
(define-constant COSMIC_JUDGMENT_CYCLE u1344) ;; ~14 days in blocks (assuming 10 min/block)
(define-constant CELESTIAL_THRESHOLD u500) ;; 50.0% represented as 500/1000
(define-constant GALACTIC_LIMIT u1000000000) ;; Maximum amount allowed for allocations
(define-constant ORBIT_NAME_MIN u4)
(define-constant ORBIT_LORE_MIN u10)

;; Error codes
(define-constant ERR_COSMIC_TRESPASS (err u100))
(define-constant ERR_MALFORMED_ORBIT (err u101))
(define-constant ERR_DUPLICATE_ALIGNMENT (err u102))
(define-constant ERR_INSUFFICIENT_STARDUST (err u103))
(define-constant ERR_ALIGNMENT_SEALED (err u104))
(define-constant ERR_CONSTELLATION_BREACH (err u105))
(define-constant ERR_ORBIT_REJECTED (err u106))
(define-constant ERR_COSMIC_FLOW_BREACH (err u107))
(define-constant ERR_INVALID_CONSTELLATION_COUNT (err u108))
(define-constant ERR_INSUFFICIENT_ORBIT_NAME (err u109))
(define-constant ERR_INSUFFICIENT_ORBIT_LORE (err u110))

;; Data Maps and Variables
(define-map CosmicOrbits
    { orbit-id: uint }
    {
        navigator: principal,
        orbit-name: (string-ascii 100),
        orbit-lore: (string-ascii 500),
        stardust-total: uint,
        constellation-count: uint,
        current-constellation: uint,
        genesis-block: uint,
        omega-block: uint,
        flux-state: (string-ascii 20),
        celestial-favor: uint,
        celestial-opposition: uint,
        total-cosmic-influence: uint
    }
)

(define-map Constellations
    { orbit-id: uint, constellation-id: uint }
    {
        stardust-flow: uint,
        celestial-purpose: (string-ascii 200),
        astral-phase: (string-ascii 20),
        nebula-evidence: (optional (string-ascii 200))
    }
)

(define-map CosmicAlignments
    { orbit-id: uint, celestial-being: principal }
    {
        stardust-quantity: uint,
        astral-position: bool,
        locked-stardust: uint
    }
)

(define-map StardustVaults
    { celestial-being: principal }
    { vault-total: uint }
)

(define-data-var orbit-nexus uint u0)

;; Private functions
(define-private (is-nebula-keeper)
    (is-eq tx-sender NEBULA_KEEPER)
)

(define-private (calculate-cosmic-influence (stardust-quantity uint))
    stardust-quantity
)

(define-private (is-valid-orbit-id (orbit-id uint))
    (<= orbit-id (var-get orbit-nexus))
)

(define-private (is-valid-constellation-id (constellation-id uint) (constellation-count uint))
    (< constellation-id constellation-count)
)

(define-private (is-valid-stardust-flow (stardust-flow uint))
    (and (> stardust-flow u0) (<= stardust-flow GALACTIC_LIMIT))
)

(define-private (is-valid-orbit-name (orbit-name (string-ascii 100)))
    (>= (len orbit-name) ORBIT_NAME_MIN)
)

(define-private (is-valid-orbit-lore (orbit-lore (string-ascii 500)))
    (>= (len orbit-lore) ORBIT_LORE_MIN)
)

(define-private (process-cosmic-alignment (astral-position bool) (cosmic-influence uint) (orbit-data (tuple (celestial-favor uint) (celestial-opposition uint) (total-cosmic-influence uint))))
    (let (
        (validated-position (sanitize-astral-position astral-position))
        (current-favor (get celestial-favor orbit-data))
        (current-opposition (get celestial-opposition orbit-data))
        (current-total-influence (get total-cosmic-influence orbit-data))
    )
        {
            celestial-favor: (if validated-position 
                (+ current-favor cosmic-influence)
                current-favor
            ),
            celestial-opposition: (if validated-position
                current-opposition
                (+ current-opposition cosmic-influence)
            ),
            total-cosmic-influence: (+ current-total-influence cosmic-influence)
        }
    )
)

(define-private (sanitize-astral-position (astral-position bool))
    (if astral-position
        true
        false
    )
)

(define-private (merge-cosmic-flux (orbit-map {
        navigator: principal,
        orbit-name: (string-ascii 100),
        orbit-lore: (string-ascii 500),
        stardust-total: uint,
        constellation-count: uint,
        current-constellation: uint,
        genesis-block: uint,
        omega-block: uint,
        flux-state: (string-ascii 20),
        celestial-favor: uint,
        celestial-opposition: uint,
        total-cosmic-influence: uint
    }) 
    (alignment-updates {
        celestial-favor: uint,
        celestial-opposition: uint,
        total-cosmic-influence: uint
    }))
    (merge orbit-map
        {
            celestial-favor: (get celestial-favor alignment-updates),
            celestial-opposition: (get celestial-opposition alignment-updates),
            total-cosmic-influence: (get total-cosmic-influence alignment-updates)
        }
    )
)

;; Public functions
(define-public (create-orbit (orbit-name (string-ascii 100)) 
                          (orbit-lore (string-ascii 500)) 
                          (stardust-total uint)
                          (constellation-count uint))
    (begin
        (asserts! (is-valid-orbit-name orbit-name) ERR_INSUFFICIENT_ORBIT_NAME)
        (asserts! (is-valid-orbit-lore orbit-lore) ERR_INSUFFICIENT_ORBIT_LORE)
        (asserts! (is-valid-stardust-flow stardust-total) ERR_COSMIC_FLOW_BREACH)
        (asserts! (and (> constellation-count u0) (<= constellation-count u10)) ERR_INVALID_CONSTELLATION_COUNT)
        
        (let ((orbit-id (+ (var-get orbit-nexus) u1)))
            (map-set CosmicOrbits
                { orbit-id: orbit-id }
                {
                    navigator: tx-sender,
                    orbit-name: orbit-name,
                    orbit-lore: orbit-lore,
                    stardust-total: stardust-total,
                    constellation-count: constellation-count,
                    current-constellation: u0,
                    genesis-block: block-height,
                    omega-block: (+ block-height COSMIC_JUDGMENT_CYCLE),
                    flux-state: "ACTIVE",
                    celestial-favor: u0,
                    celestial-opposition: u0,
                    total-cosmic-influence: u0
                }
            )
            (var-set orbit-nexus orbit-id)
            (ok orbit-id)
        )
    )
)

(define-public (forge-constellation (orbit-id uint) 
                                (constellation-id uint)
                                (stardust-flow uint)
                                (celestial-purpose (string-ascii 200)))
    (begin
        (asserts! (is-valid-orbit-lore celestial-purpose) ERR_INSUFFICIENT_ORBIT_LORE)
        (let ((orbit (unwrap! (map-get? CosmicOrbits {orbit-id: orbit-id}) ERR_MALFORMED_ORBIT)))
            (asserts! (is-valid-orbit-id orbit-id) ERR_MALFORMED_ORBIT)
            (asserts! (is-valid-stardust-flow stardust-flow) ERR_COSMIC_FLOW_BREACH)
            (asserts! (is-valid-constellation-id constellation-id (get constellation-count orbit)) ERR_CONSTELLATION_BREACH)
            (asserts! (is-eq (get navigator orbit) tx-sender) ERR_COSMIC_TRESPASS)
            
            (map-set Constellations
                { orbit-id: orbit-id, constellation-id: constellation-id }
                {
                    stardust-flow: stardust-flow,
                    celestial-purpose: celestial-purpose,
                    astral-phase: "PENDING",
                    nebula-evidence: none
                }
            )
            (ok true)
        )
    )
)

(define-public (align-with-orbit (orbit-id uint) (favorable-alignment bool) (stardust-quantity uint))
    (let (
        (orbit (unwrap! (map-get? CosmicOrbits {orbit-id: orbit-id}) ERR_MALFORMED_ORBIT))
        (current-block block-height)
        (cosmic-influence (calculate-cosmic-influence stardust-quantity))
        (validated-alignment (sanitize-astral-position favorable-alignment))
    )
        (asserts! (is-valid-orbit-id orbit-id) ERR_MALFORMED_ORBIT)
        (asserts! (>= stardust-quantity STARDUST_MINIMUM) ERR_INSUFFICIENT_STARDUST)
        (asserts! (<= current-block (get omega-block orbit)) ERR_ALIGNMENT_SEALED)
        (asserts! (is-none (map-get? CosmicAlignments {orbit-id: orbit-id, celestial-being: tx-sender})) ERR_DUPLICATE_ALIGNMENT)
        
        (try! (stx-transfer? stardust-quantity tx-sender (as-contract tx-sender)))
        
        ;; Record alignment with validated boolean
        (map-set CosmicAlignments
            {orbit-id: orbit-id, celestial-being: tx-sender}
            {
                stardust-quantity: stardust-quantity,
                astral-position: validated-alignment,
                locked-stardust: stardust-quantity
            }
        )
        
        ;; Process alignment and update orbit
        (let (
            (updated-influences (process-cosmic-alignment 
                validated-alignment
                cosmic-influence
                {
                    celestial-favor: (get celestial-favor orbit),
                    celestial-opposition: (get celestial-opposition orbit),
                    total-cosmic-influence: (get total-cosmic-influence orbit)
                }
            ))
        )
            (map-set CosmicOrbits
                {orbit-id: orbit-id}
                (merge-cosmic-flux orbit updated-influences)
            )
            (ok true)
        )
    )
)

(define-public (submit-nebula-evidence 
    (orbit-id uint)
    (constellation-id uint)
    (stellar-proof (string-ascii 200)))
    
    (let (
        (orbit (unwrap! (map-get? CosmicOrbits {orbit-id: orbit-id}) ERR_MALFORMED_ORBIT))
        (constellation (unwrap! (map-get? Constellations {orbit-id: orbit-id, constellation-id: constellation-id}) ERR_CONSTELLATION_BREACH))
    )
        (asserts! (is-valid-orbit-id orbit-id) ERR_MALFORMED_ORBIT)
        (asserts! (is-valid-constellation-id constellation-id (get constellation-count orbit)) ERR_CONSTELLATION_BREACH)
        (asserts! (is-eq (get navigator orbit) tx-sender) ERR_COSMIC_TRESPASS)
        (asserts! (is-eq constellation-id (get current-constellation orbit)) ERR_CONSTELLATION_BREACH)
        
        (map-set Constellations
            {orbit-id: orbit-id, constellation-id: constellation-id}
            (merge constellation
                {
                    astral-phase: "AWAITING_ALIGNMENT",
                    nebula-evidence: (some stellar-proof)
                }
            )
        )
        (ok true)
    )
)

(define-public (bless-constellation (orbit-id uint) (constellation-id uint))
    (let (
        (orbit (unwrap! (map-get? CosmicOrbits {orbit-id: orbit-id}) ERR_MALFORMED_ORBIT))
        (constellation (unwrap! (map-get? Constellations {orbit-id: orbit-id, constellation-id: constellation-id}) ERR_CONSTELLATION_BREACH))
    )
        (asserts! (is-valid-orbit-id orbit-id) ERR_MALFORMED_ORBIT)
        (asserts! (is-valid-constellation-id constellation-id (get constellation-count orbit)) ERR_CONSTELLATION_BREACH)
        (asserts! (is-nebula-keeper) ERR_COSMIC_TRESPASS)
        
        ;; Transfer constellation stardust to navigator
        (try! (as-contract (stx-transfer? (get stardust-flow constellation) tx-sender (get navigator orbit))))
        
        ;; Update constellation status
        (map-set Constellations
            {orbit-id: orbit-id, constellation-id: constellation-id}
            (merge constellation {astral-phase: "HARMONIZED"})
        )
        
        ;; Update orbit current constellation
        (map-set CosmicOrbits
            {orbit-id: orbit-id}
            (merge orbit
                {
                    current-constellation: (+ constellation-id u1),
                    flux-state: (if (>= (+ constellation-id u1) (get constellation-count orbit))
                        "HARMONIZED"
                        "ACTIVE"
                    )
                }
            )
        )
        (ok true)
    )
)

;; Read-only functions
(define-read-only (observe-orbit (orbit-id uint))
    (map-get? CosmicOrbits {orbit-id: orbit-id})
)

(define-read-only (observe-constellation (orbit-id uint) (constellation-id uint))
    (map-get? Constellations {orbit-id: orbit-id, constellation-id: constellation-id})
)

(define-read-only (observe-alignment (orbit-id uint) (celestial-being principal))
    (map-get? CosmicAlignments {orbit-id: orbit-id, celestial-being: celestial-being})
)

(define-read-only (calculate-orbit-fate (orbit-id uint))
    (let ((orbit (unwrap! (map-get? CosmicOrbits {orbit-id: orbit-id}) ERR_MALFORMED_ORBIT)))
        (asserts! (is-valid-orbit-id orbit-id) ERR_MALFORMED_ORBIT)
        (if (>= block-height (get omega-block orbit))
            (let (
                (total-influence (get total-cosmic-influence orbit))
                (favorable-influence (get celestial-favor orbit))
            )
                (if (and
                    (> total-influence u0)
                    (>= (* favorable-influence u1000) (* total-influence CELESTIAL_THRESHOLD))
                )
                    (ok "HARMONIZED")
                    (ok "DISCORDANT")
                )
            )
            (ok "ALIGNMENT_OPEN")
        )
    )
)