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
    vehicle_model,
    vehicle_year,
    vehicle_capacity,
    status,
    background_check_status
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10
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

-- name: GetDriverByLicenseNumber :one
SELECT * FROM drivers
WHERE license_number = $1 LIMIT 1;

-- name: GetDriverByVehiclePlate :one
SELECT * FROM drivers
WHERE vehicle_plate = $1 LIMIT 1;

-- name: UpdateDriver :one
UPDATE drivers
SET 
    license_number = COALESCE(sqlc.narg('license_number'), license_number),
    license_expiry = COALESCE(sqlc.narg('license_expiry'), license_expiry),
    vehicle_type = COALESCE(sqlc.narg('vehicle_type'), vehicle_type),
    vehicle_plate = COALESCE(sqlc.narg('vehicle_plate'), vehicle_plate),
    vehicle_model = COALESCE(sqlc.narg('vehicle_model'), vehicle_model),
    vehicle_year = COALESCE(sqlc.narg('vehicle_year'), vehicle_year),
    vehicle_capacity = COALESCE(sqlc.narg('vehicle_capacity'), vehicle_capacity),
    status = COALESCE(sqlc.narg('status'), status),
    background_check_status = COALESCE(sqlc.narg('background_check_status'), background_check_status),
    background_check_date = COALESCE(sqlc.narg('background_check_date'), background_check_date),
    profile_verified = COALESCE(sqlc.narg('profile_verified'), profile_verified),
    documents_verified = COALESCE(sqlc.narg('documents_verified'), documents_verified)
WHERE id = $1
RETURNING *;

-- name: UpdateDriverStatus :exec
UPDATE drivers
SET status = $2
WHERE driver_id = $1;

-- name: UpdateDriverLocation :exec
UPDATE drivers
SET 
    current_latitude = $2,
    current_longitude = $3,
    last_location_update = now()
WHERE driver_id = $1;

-- name: UpdateDriverVerification :exec
UPDATE drivers
SET 
    background_check_status = $2,
    background_check_date = $3,
    profile_verified = $4,
    documents_verified = $5
WHERE driver_id = $1;

-- name: IncrementDriverDeliveries :exec
UPDATE drivers
SET total_deliveries = total_deliveries + 1
WHERE driver_id = $1;

-- name: ListAvailableDrivers :many
SELECT * FROM drivers
WHERE status = 'online'
AND background_check_status = 'approved'
AND profile_verified = true
AND documents_verified = true
ORDER BY rating DESC, total_deliveries DESC;

-- name: ListDriversByVehicleType :many
SELECT * FROM drivers
WHERE vehicle_type = $1
AND status = 'online'
AND background_check_status = 'approved'
ORDER BY rating DESC;

-- name: ListDriversByStatus :many
SELECT * FROM drivers
WHERE status = $1
ORDER BY created_at DESC;

-- name: ListDriversWithExpiredLicenses :many
SELECT * FROM drivers
WHERE license_expiry < now() + interval '30 days'
ORDER BY license_expiry ASC;

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

-- name: GetDriverStats :one
SELECT 
    driver_id,
    rating,
    total_deliveries,
    completed_deliveries,
    CASE 
        WHEN total_deliveries > 0 THEN 
            ROUND((completed_deliveries::decimal / total_deliveries * 100), 2)
        ELSE 0 
    END AS completion_rate
FROM drivers
WHERE driver_id = $1;

-- name: FindNearbyDrivers :many
SELECT 
    driver_id,
    user_id,
    vehicle_type,
    rating,
    current_latitude,
    current_longitude,
    ST_Distance(
        current_location,
        ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography
    ) / 1000 AS distance_km
FROM drivers
WHERE status = 'online'
AND background_check_status = 'approved'
AND current_location IS NOT NULL
AND ST_DWithin(
    current_location,
    ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography,
    $3 * 1000
)
ORDER BY distance_km ASC
LIMIT $4;