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

-- name: UpdateUser :one
UPDATE users
SET 
    first_name = COALESCE($2, first_name),
    last_name = COALESCE($3, last_name),
    email = COALESCE($4, email),
    phone = COALESCE($5, phone),
    avatar = COALESCE($6, avatar),
    status = COALESCE($7, status),
    updated_at = now()
WHERE id = $1
RETURNING *;

-- name: UpdateUserPassword :exec
UPDATE users
SET 
    password = $2,
    updated_at = now()
WHERE id = $1;

-- name: UpdateUserTokens :exec
UPDATE users
SET 
    token = $2,
    refresh_token = $3,
    updated_at = now()
WHERE id = $1;

-- name: DeleteUser :exec
DELETE FROM users
WHERE id = $1;

-- name: DeactivateUser :one
UPDATE users
SET 
    status = 'inactive',
    updated_at = now()
WHERE id = $1
RETURNING *;
