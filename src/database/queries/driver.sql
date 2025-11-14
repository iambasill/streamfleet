
-- ============================================
-- DRIVER QUERIES
-- ============================================

-- name: CreateDriver :one
INSERT INTO drivers (
    user_id,
    license_number,
    license_expiry,
    vehicle_type,
    vehicle_plate,
    vehicle_capacity,
    status,
    background_check_status
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8
)
RETURNING *;

-- name: GetDriver :one
SELECT * FROM drivers
WHERE id = $1 LIMIT 1;

-- name: GetDriverByUserID :one
SELECT * FROM drivers
WHERE user_id = $1 LIMIT 1;

-- name: GetDriverByDriverID :one
SELECT * FROM drivers
WHERE driver_id = $1 LIMIT 1;

-- name: UpdateDriver :one
UPDATE drivers
SET 
    license_number = COALESCE($2, license_number),
    license_expiry = COALESCE($3, license_expiry),
    vehicle_type = COALESCE($4, vehicle_type),
    vehicle_plate = COALESCE($5, vehicle_plate),
    vehicle_capacity = COALESCE($6, vehicle_capacity),
    status = COALESCE($7, status),
    background_check_status = COALESCE($8, background_check_status),
    updated_at = now()
WHERE id = $1
RETURNING *;

-- name: UpdateDriverStatus :exec
UPDATE drivers
SET 
    status = $2,
    updated_at = now()
WHERE driver_id = $1;

-- name: UpdateDriverRating :exec
UPDATE drivers
SET 
    rating = $2,
    total_deliveries = total_deliveries + 1,
    updated_at = now()
WHERE driver_id = $1;

-- name: ListAvailableDrivers :many
SELECT * FROM drivers
WHERE status = 'online'
AND background_check_status = 'approved'
ORDER BY rating DESC, total_deliveries DESC;

-- name: ListDriversByVehicleType :many
SELECT * FROM drivers
WHERE vehicle_type = $1
AND status = 'online'
ORDER BY rating DESC;

-- name: GetDriverWithUser :one
SELECT 
    d.*,
    u.first_name,
    u.last_name,
    u.email,
    u.phone,
    u.avatar
FROM drivers d
INNER JOIN users u ON d.user_id = u.user_id
WHERE d.driver_id = $1
LIMIT 1;

