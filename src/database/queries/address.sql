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
    is_default
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11
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
ORDER BY is_default DESC, created_at DESC;

-- name: GetDefaultAddress :one
SELECT * FROM addresses
WHERE user_id = $1 AND is_default = true
LIMIT 1;

-- name: UpdateAddress :one
UPDATE addresses
SET 
    label = COALESCE($2, label),
    street_address = COALESCE($3, street_address),
    city = COALESCE($4, city),
    state = COALESCE($5, state),
    postal_code = COALESCE($6, postal_code),
    country = COALESCE($7, country),
    latitude = COALESCE($8, latitude),
    longitude = COALESCE($9, longitude),
    instructions = COALESCE($10, instructions),
    is_default = COALESCE($11, is_default),
    updated_at = now()
WHERE id = $1
RETURNING *;

-- name: SetDefaultAddress :exec
UPDATE addresses
SET is_default = CASE 
    WHEN id = $2 THEN true 
    ELSE false 
END,
updated_at = now()
WHERE user_id = $1;

-- name: DeleteAddress :exec
DELETE FROM addresses
WHERE id = $1;