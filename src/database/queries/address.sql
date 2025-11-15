-- ============================================
-- ADDRESS QUERIES
-- ============================================

-- name: CreateAddress :one
INSERT INTO addresses (
    user_id,
    label,
    street_address,
    city,
    state,
    postal_code,
    country,
    latitude,
    longitude,
    instructions,
    is_default,
    is_active
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12
)
RETURNING *;

-- name: GetAddress :one
SELECT * FROM addresses
WHERE id = $1 LIMIT 1;

-- name: GetAddressByAddressID :one
SELECT * FROM addresses
WHERE address_id = $1 LIMIT 1;

-- name: ListUserAddresses :many
SELECT * FROM addresses
WHERE user_id = $1
AND is_active = true
ORDER BY is_default DESC, created_at DESC;

-- name: ListAllUserAddresses :many
SELECT * FROM addresses
WHERE user_id = $1
ORDER BY is_default DESC, is_active DESC, created_at DESC;

-- name: GetDefaultAddress :one
SELECT * FROM addresses
WHERE user_id = $1 
AND is_default = true 
AND is_active = true
LIMIT 1;

-- name: UpdateAddress :one
UPDATE addresses
SET 
    label = COALESCE(sqlc.narg('label'), label),
    street_address = COALESCE(sqlc.narg('street_address'), street_address),
    city = COALESCE(sqlc.narg('city'), city),
    state = COALESCE(sqlc.narg('state'), state),
    postal_code = COALESCE(sqlc.narg('postal_code'), postal_code),
    country = COALESCE(sqlc.narg('country'), country),
    latitude = COALESCE(sqlc.narg('latitude'), latitude),
    longitude = COALESCE(sqlc.narg('longitude'), longitude),
    instructions = COALESCE(sqlc.narg('instructions'), instructions),
    is_default = COALESCE(sqlc.narg('is_default'), is_default),
    is_active = COALESCE(sqlc.narg('is_active'), is_active)
WHERE id = $1
RETURNING *;

-- name: SetDefaultAddress :exec
UPDATE addresses
SET is_default = CASE 
    WHEN address_id = $2 THEN true 
    ELSE false 
END
WHERE user_id = $1;

-- name: DeactivateAddress :exec
UPDATE addresses
SET is_active = false
WHERE id = $1;

-- name: ActivateAddress :exec
UPDATE addresses
SET is_active = true
WHERE id = $1;

-- name: DeleteAddress :exec
DELETE FROM addresses
WHERE id = $1;

-- name: SearchAddressesByCity :many
SELECT * FROM addresses
WHERE city ILIKE $1
AND is_active = true
ORDER BY created_at DESC
LIMIT $2;

-- name: GetAddressesByPostalCode :many
SELECT * FROM addresses
WHERE postal_code = $1
AND is_active = true
ORDER BY created_at DESC;

-- name: FindNearbyAddresses :many
SELECT 
    address_id,
    user_id,
    street_address,
    city,
    state,
    latitude,
    longitude,
    ST_Distance(
        location,
        ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography
    ) / 1000 AS distance_km
FROM addresses
WHERE is_active = true
AND location IS NOT NULL
AND ST_DWithin(
    location,
    ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography,
    $3 * 1000
)
ORDER BY distance_km ASC
LIMIT $4;