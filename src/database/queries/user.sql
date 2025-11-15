-- name: CreateUser :one
INSERT INTO users (
    first_name,
    last_name,
    email,
    password,
    phone,
    role,
    status,
    avatar
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8
)
RETURNING *;

-- name: GetUser :one
SELECT * FROM users
WHERE id = $1 LIMIT 1;

-- name: GetUserForUpdate :one
SELECT * FROM users
WHERE id = $1 LIMIT 1
FOR UPDATE;

-- name: GetUserByEmail :one
SELECT * FROM users
WHERE email = $1 LIMIT 1;

-- name: GetUserByEmailForUpdate :one
SELECT * FROM users
WHERE email = $1 LIMIT 1
FOR UPDATE;

-- name: GetUserByUserID :one
SELECT * FROM users
WHERE user_id = $1 LIMIT 1;

-- name: GetUserByUserIDForUpdate :one
SELECT * FROM users
WHERE user_id = $1 LIMIT 1
FOR UPDATE;

-- name: ListUsers :many
SELECT * FROM users
ORDER BY created_at DESC
LIMIT $1 OFFSET $2;

-- name: ListUsersByRole :many
SELECT * FROM users
WHERE role = $1
ORDER BY created_at DESC;

-- name: ListUsersByStatus :many
SELECT * FROM users
WHERE status = $1
ORDER BY created_at DESC;

-- name: ListUsersByRoleAndStatus :many
SELECT * FROM users
WHERE role = $1 AND status = $2
ORDER BY created_at DESC;

-- name: UpdateUser :one
UPDATE users
SET 
    first_name = COALESCE(sqlc.narg('first_name'), first_name),
    last_name = COALESCE(sqlc.narg('last_name'), last_name),
    email = COALESCE(sqlc.narg('email'), email),
    phone = COALESCE(sqlc.narg('phone'), phone),
    avatar = COALESCE(sqlc.narg('avatar'), avatar),
    status = COALESCE(sqlc.narg('status'), status)
WHERE id = $1
RETURNING *;

-- name: UpdateUserPassword :exec
UPDATE users
SET password = $2
WHERE id = $1;

-- name: UpdateUserTokens :exec
UPDATE users
SET 
    token = $2,
    refresh_token = $3
WHERE id = $1;

-- name: UpdateUserLastLogin :exec
UPDATE users
SET last_login_at = now()
WHERE id = $1;

-- name: ClearUserTokens :exec
UPDATE users
SET 
    token = NULL,
    refresh_token = NULL
WHERE id = $1;

-- name: DeleteUser :exec
DELETE FROM users
WHERE id = $1;

-- name: DeactivateUser :one
UPDATE users
SET status = 'inactive'
WHERE id = $1
RETURNING *;

-- name: SuspendUser :one
UPDATE users
SET status = 'suspended'
WHERE id = $1
RETURNING *;

-- name: ActivateUser :one
UPDATE users
SET status = 'active'
WHERE id = $1
RETURNING *;