-- ============================================
-- CUSTOMER QUERIES
-- ============================================

-- name: CreateCustomer :one
INSERT INTO customers (
    user_id,
    company_name,
    business_type,
    billing_address,
    payment_method,
    credit_limit
) VALUES (
    $1, $2, $3, $4, $5, $6
)
RETURNING *;

-- name: GetCustomer :one
SELECT * FROM customers
WHERE id = $1 LIMIT 1;

-- name: GetCustomerByUserID :one
SELECT * FROM customers
WHERE user_id = $1 LIMIT 1;

-- name: GetCustomerByCustomerID :one
SELECT * FROM customers
WHERE customer_id = $1 LIMIT 1;

-- name: UpdateCustomer :one
UPDATE customers
SET 
    company_name = COALESCE(sqlc.narg('company_name'), company_name),
    business_type = COALESCE(sqlc.narg('business_type'), business_type),
    billing_address = COALESCE(sqlc.narg('billing_address'), billing_address),
    payment_method = COALESCE(sqlc.narg('payment_method'), payment_method),
    credit_limit = COALESCE(sqlc.narg('credit_limit'), credit_limit)
WHERE id = $1
RETURNING *;

-- name: UpdateCustomerCreditLimit :exec
UPDATE customers
SET credit_limit = $2
WHERE customer_id = $1;

-- name: ListCustomers :many
SELECT * FROM customers
ORDER BY created_at DESC
LIMIT $1 OFFSET $2;

-- name: ListCustomersByBusinessType :many
SELECT * FROM customers
WHERE business_type = $1
ORDER BY total_spent DESC;

-- name: GetTopCustomers :many
SELECT * FROM customers
WHERE total_spent > 0
ORDER BY total_spent DESC
LIMIT $1;

-- name: GetCustomerStats :one
SELECT 
    customer_id,
    total_orders,
    total_spent,
    credit_limit,
    credit_limit - total_spent AS available_credit
FROM customers
WHERE customer_id = $1;

-- name: GetCustomerWithUser :one
SELECT 
    c.*,
    u.first_name,
    u.last_name,
    u.email,
    u.phone,
    u.avatar,
    u.status as user_status
FROM customers c
INNER JOIN users u ON c.user_id = u.user_id
WHERE c.customer_id = $1
LIMIT 1;