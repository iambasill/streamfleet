
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
    company_name = COALESCE($2, company_name),
    business_type = COALESCE($3, business_type),
    billing_address = COALESCE($4, billing_address),
    payment_method = COALESCE($5, payment_method),
    credit_limit = COALESCE($6, credit_limit),
    updated_at = now()
WHERE id = $1
RETURNING *;

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
