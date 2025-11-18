-- ============================================
-- USER SESSIONS QUERIES
-- ============================================

-- name: CreateUserSession :one
INSERT INTO user_sessions (
    user_id,
    session_token,
    expires_at
) VALUES (
    $1, $2, $3
)
RETURNING *;

-- name: GetUserSession :one
SELECT * FROM user_sessions
WHERE session_token = $1 AND expires_at = $2  LIMIT 1;

-- name: DeleteUserSession :exec
DELETE FROM user_sessions
WHERE id = $1;

