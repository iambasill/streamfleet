-- StreamFleet Database Schema (Corrected)
-- PostgreSQL 14+

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- Create ENUM types for type safety
CREATE TYPE user_role AS ENUM ('admin', 'dispatcher', 'customer', 'driver');
CREATE TYPE user_status AS ENUM ('active', 'suspended', 'inactive');
CREATE TYPE driver_status AS ENUM ('online', 'offline', 'on_delivery', 'break');
CREATE TYPE driver_vehicle_type AS ENUM ('motorcycle', 'car', 'van', 'truck');
CREATE TYPE background_check_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE business_type AS ENUM ('individual', 'business', 'enterprise');
CREATE TYPE payment_method_type AS ENUM ('credit_card', 'debit_card', 'wallet', 'invoice');
CREATE TYPE package_priority AS ENUM ('express', 'standard', 'economy');
CREATE TYPE package_status AS ENUM ('pending', 'assigned', 'picked_up', 'in_transit', 'out_for_delivery', 'delivered', 'failed', 'cancelled');
CREATE TYPE delivery_status AS ENUM ('assigned', 'in_progress', 'completed', 'failed', 'cancelled');
CREATE TYPE route_status AS ENUM ('planned', 'in_progress', 'completed', 'cancelled');
CREATE TYPE stop_type AS ENUM ('pickup', 'delivery');
CREATE TYPE stop_status AS ENUM ('pending', 'arrived', 'completed', 'skipped');
CREATE TYPE event_type AS ENUM ('created', 'assigned', 'picked_up', 'in_transit', 'out_for_delivery', 'delivered', 'exception', 'failed', 'cancelled');
CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'failed', 'refunded');
CREATE TYPE rating_type AS ENUM ('driver_rating', 'customer_rating');
CREATE TYPE maintenance_type AS ENUM ('inspection', 'repair', 'service');
CREATE TYPE maintenance_status AS ENUM ('scheduled', 'completed', 'overdue');
CREATE TYPE zone_type AS ENUM ('urban', 'suburban', 'rural');

-- =============================================
-- USERS TABLE (Base table for all user types)
-- =============================================
CREATE TABLE "users" (
  "id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  "user_id" varchar(100) UNIQUE NOT NULL DEFAULT ('USR-' || substring(uuid_generate_v4()::text, 1, 8)),
  "first_name" varchar(100) NOT NULL,
  "last_name" varchar(100) NOT NULL,
  "email" varchar(255) UNIQUE NOT NULL,
  "password" varchar(255) NOT NULL,
  "phone" varchar(20) NOT NULL,
  "avatar" varchar(500),
  "role" user_role NOT NULL,
  "status" user_status NOT NULL DEFAULT 'active',
  "token" text,
  "refresh_token" text,
  "last_login_at" timestamp,
  "created_at" timestamp NOT NULL DEFAULT now(),
  "updated_at" timestamp NOT NULL DEFAULT now(),
  CONSTRAINT "check_email_format" CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- =============================================
-- DRIVERS TABLE
-- =============================================
CREATE TABLE "drivers" (
  "id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  "driver_id" varchar(100) UNIQUE NOT NULL DEFAULT ('DRV-' || substring(uuid_generate_v4()::text, 1, 8)),
  "user_id" varchar(100) UNIQUE NOT NULL,
  "license_number" varchar(50) UNIQUE NOT NULL,
  "license_expiry" timestamp NOT NULL,
  "vehicle_type" driver_vehicle_type NOT NULL,
  "vehicle_plate" varchar(20) UNIQUE NOT NULL,
  "vehicle_model" varchar(100),
  "vehicle_year" int,
  "vehicle_capacity" decimal(10,2) NOT NULL,
  "status" driver_status NOT NULL DEFAULT 'offline',
  "rating" decimal(3,2) DEFAULT 5.0,
  "total_deliveries" int DEFAULT 0,
  "completed_deliveries" int DEFAULT 0,
  "background_check_status" background_check_status NOT NULL DEFAULT 'pending',
  "background_check_date" timestamp,
  "profile_verified" boolean DEFAULT false,
  "documents_verified" boolean DEFAULT false,
  "current_latitude" decimal(10,8),
  "current_longitude" decimal(11,8),
  "current_location" geography(POINT, 4326),
  "last_location_update" timestamp,
  "created_at" timestamp NOT NULL DEFAULT now(),
  "updated_at" timestamp NOT NULL DEFAULT now(),
  CONSTRAINT "check_rating_range" CHECK (rating >= 0 AND rating <= 5),
  CONSTRAINT "check_vehicle_capacity" CHECK (vehicle_capacity > 0),
  CONSTRAINT "check_license_not_expired" CHECK (license_expiry > now()),
  CONSTRAINT "check_total_deliveries" CHECK (total_deliveries >= 0),
  CONSTRAINT "check_completed_deliveries" CHECK (completed_deliveries >= 0 AND completed_deliveries <= total_deliveries)
);

-- =============================================
-- CUSTOMERS TABLE
-- =============================================
CREATE TABLE "customers" (
  "id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  "customer_id" varchar(100) UNIQUE NOT NULL DEFAULT ('CUST-' || substring(uuid_generate_v4()::text, 1, 8)),
  "user_id" varchar(100) UNIQUE NOT NULL,
  "company_name" varchar(255),
  "business_type" business_type DEFAULT 'individual',
  "billing_address" text NOT NULL,
  "payment_method" payment_method_type,
  "credit_limit" decimal(10,2) DEFAULT 0,
  "total_spent" decimal(10,2) DEFAULT 0,
  "total_orders" int DEFAULT 0,
  "created_at" timestamp NOT NULL DEFAULT now(),
  "updated_at" timestamp NOT NULL DEFAULT now(),
  CONSTRAINT "check_credit_limit" CHECK (credit_limit >= 0),
  CONSTRAINT "check_total_spent" CHECK (total_spent >= 0),
  CONSTRAINT "check_total_orders" CHECK (total_orders >= 0)
);

-- =============================================
-- ADDRESSES TABLE
-- =============================================
CREATE TABLE "addresses" (
  "id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  "address_id" varchar(100) UNIQUE NOT NULL DEFAULT ('ADDR-' || substring(uuid_generate_v4()::text, 1, 8)),
  "user_id" varchar(100) NOT NULL,
  "label" varchar(50),
  "street_address" varchar(255) NOT NULL,
  "city" varchar(100) NOT NULL,
  "state" varchar(100) NOT NULL,
  "postal_code" varchar(20) NOT NULL,
  "country" varchar(100) NOT NULL DEFAULT 'Nigeria',
  "latitude" decimal(10,8),
  "longitude" decimal(11,8),
  "location" geography(POINT, 4326),
  "instructions" text,
  "is_default" boolean DEFAULT false,
  "is_active" boolean DEFAULT true,
  "created_at" timestamp NOT NULL DEFAULT now(),
  "updated_at" timestamp NOT NULL DEFAULT now(),
  CONSTRAINT "check_coordinates_valid" CHECK (
    (latitude IS NULL AND longitude IS NULL) OR 
    (latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180)
  )
);

-- =============================================
-- PACKAGES TABLE
-- =============================================
CREATE TABLE "packages" (
  "id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  "package_id" varchar(100) UNIQUE NOT NULL DEFAULT ('PKG-' || substring(uuid_generate_v4()::text, 1, 8)),
  "tracking_number" varchar(50) UNIQUE NOT NULL DEFAULT ('TRK-' || upper(substring(uuid_generate_v4()::text, 1, 12))),
  "customer_id" varchar(100) NOT NULL,
  "description" text NOT NULL,
  "weight" decimal(10,2) NOT NULL,
  "dimensions" varchar(50),
  "category" varchar(50) NOT NULL,
  "value" decimal(10,2) DEFAULT 0,
  "priority" package_priority NOT NULL DEFAULT 'standard',
  "special_handling" text,
  "fragile" boolean DEFAULT false,
  "requires_signature" boolean DEFAULT false,
  "pickup_address_id" varchar(100) NOT NULL,
  "delivery_address_id" varchar(100) NOT NULL,
  "status" package_status NOT NULL DEFAULT 'pending',
  "deleted_at" timestamp,
  "created_at" timestamp NOT NULL DEFAULT now(),
  "updated_at" timestamp NOT NULL DEFAULT now(),
  CONSTRAINT "check_weight_positive" CHECK (weight > 0),
  CONSTRAINT "check_value_non_negative" CHECK (value >= 0),
  CONSTRAINT "check_different_addresses" CHECK (pickup_address_id != delivery_address_id)
);

-- =============================================
-- DELIVERIES TABLE
-- =============================================
CREATE TABLE "deliveries" (
  "id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  "delivery_id" varchar(100) UNIQUE NOT NULL DEFAULT ('DEL-' || substring(uuid_generate_v4()::text, 1, 8)),
  "package_id" varchar(100) NOT NULL,
  "driver_id" varchar(100),
  "route_id" varchar(100),
  "scheduled_pickup_time" timestamp,
  "actual_pickup_time" timestamp,
  "scheduled_delivery_time" timestamp,
  "estimated_delivery_time" timestamp,
  "actual_delivery_time" timestamp,
  "delivery_status" delivery_status NOT NULL DEFAULT 'assigned',
  "pickup_signature" varchar(500),
  "delivery_signature" varchar(500),
  "delivery_proof" varchar(500),
  "delivery_notes" text,
  "failure_reason" text,
  "distance_km" decimal(10,2),
  "duration_minutes" int,
  "is_delayed" boolean GENERATED ALWAYS AS (
    CASE 
      WHEN actual_delivery_time IS NOT NULL AND estimated_delivery_time IS NOT NULL 
      THEN actual_delivery_time > estimated_delivery_time 
      ELSE false 
    END
  ) STORED,
  "deleted_at" timestamp,
  "created_at" timestamp NOT NULL DEFAULT now(),
  "updated_at" timestamp NOT NULL DEFAULT now(),
  CONSTRAINT "check_distance_positive" CHECK (distance_km IS NULL OR distance_km >= 0),
  CONSTRAINT "check_duration_positive" CHECK (duration_minutes IS NULL OR duration_minutes >= 0),
  CONSTRAINT "check_pickup_before_delivery" CHECK (
    actual_pickup_time IS NULL OR actual_delivery_time IS NULL OR 
    actual_pickup_time < actual_delivery_time
  )
);

-- =============================================
-- ROUTES TABLE
-- =============================================
CREATE TABLE "routes" (
  "id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  "route_id" varchar(100) UNIQUE NOT NULL DEFAULT ('RTE-' || substring(uuid_generate_v4()::text, 1, 8)),
  "driver_id" varchar(100) NOT NULL,
  "route_name" varchar(255),
  "start_location" varchar(255) NOT NULL,
  "end_location" varchar(255),
  "status" route_status NOT NULL DEFAULT 'planned',
  "total_distance_km" decimal(10,2),
  "estimated_duration_minutes" int,
  "actual_duration_minutes" int,
  "optimization_score" decimal(5,2),
  "total_stops" int DEFAULT 0,
  "completed_stops" int DEFAULT 0,
  "started_at" timestamp,
  "completed_at" timestamp,
  "created_at" timestamp NOT NULL DEFAULT now(),
  "updated_at" timestamp NOT NULL DEFAULT now(),
  CONSTRAINT "check_distance_positive" CHECK (total_distance_km IS NULL OR total_distance_km >= 0),
  CONSTRAINT "check_duration_positive" CHECK (
    (estimated_duration_minutes IS NULL OR estimated_duration_minutes >= 0) AND
    (actual_duration_minutes IS NULL OR actual_duration_minutes >= 0)
  ),
  CONSTRAINT "check_stops_valid" CHECK (
    total_stops >= 0 AND 
    completed_stops >= 0 AND 
    completed_stops <= total_stops
  ),
  CONSTRAINT "check_completion_time" CHECK (
    started_at IS NULL OR completed_at IS NULL OR started_at < completed_at
  )
);

-- =============================================
-- ROUTE STOPS TABLE
-- =============================================
CREATE TABLE "route_stops" (
  "id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  "stop_id" varchar(100) UNIQUE NOT NULL DEFAULT ('STP-' || substring(uuid_generate_v4()::text, 1, 8)),
  "route_id" varchar(100) NOT NULL,
  "delivery_id" varchar(100) NOT NULL,
  "stop_sequence" int NOT NULL,
  "stop_type" stop_type NOT NULL,
  "address_id" varchar(100) NOT NULL,
  "scheduled_arrival" timestamp,
  "actual_arrival" timestamp,
  "scheduled_departure" timestamp,
  "actual_departure" timestamp,
  "status" stop_status NOT NULL DEFAULT 'pending',
  "dwell_time_minutes" int,
  "notes" text,
  "created_at" timestamp NOT NULL DEFAULT now(),
  "updated_at" timestamp NOT NULL DEFAULT now(),
  CONSTRAINT "check_sequence_positive" CHECK (stop_sequence > 0),
  CONSTRAINT "check_dwell_time" CHECK (dwell_time_minutes IS NULL OR dwell_time_minutes >= 0),
  CONSTRAINT "check_arrival_before_departure" CHECK (
    actual_arrival IS NULL OR actual_departure IS NULL OR 
    actual_arrival < actual_departure
  ),
  CONSTRAINT "unique_route_delivery" UNIQUE (route_id, delivery_id)
);

-- =============================================
-- TRACKING EVENTS TABLE
-- =============================================
CREATE TABLE "tracking_events" (
  "id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  "event_id" varchar(100) UNIQUE NOT NULL DEFAULT ('EVT-' || substring(uuid_generate_v4()::text, 1, 8)),
  "package_id" varchar(100) NOT NULL,
  "delivery_id" varchar(100),
  "event_type" event_type NOT NULL,
  "event_description" text NOT NULL,
  "location" varchar(255),
  "latitude" decimal(10,8),
  "longitude" decimal(11,8),
  "location_point" geography(POINT, 4326),
  "occurred_at" timestamp NOT NULL DEFAULT now(),
  "created_by" varchar(100),
  "metadata" jsonb,
  "created_at" timestamp NOT NULL DEFAULT now()
);

-- =============================================
-- DRIVER LOCATIONS TABLE
-- =============================================
CREATE TABLE "driver_locations" (
  "id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  "location_id" varchar(100) UNIQUE NOT NULL DEFAULT ('LOC-' || substring(uuid_generate_v4()::text, 1, 8)),
  "driver_id" varchar(100) NOT NULL,
  "latitude" decimal(10,8) NOT NULL,
  "longitude" decimal(11,8) NOT NULL,
  "location" geography(POINT, 4326) NOT NULL,
  "heading" decimal(5,2),
  "speed" decimal(5,2),
  "accuracy" decimal(6,2),
  "battery_level" int,
  "recorded_at" timestamp NOT NULL DEFAULT now(),
  "created_at" timestamp NOT NULL DEFAULT now(),
  CONSTRAINT "check_coordinates" CHECK (
    latitude BETWEEN -90 AND 90 AND 
    longitude BETWEEN -180 AND 180
  ),
  CONSTRAINT "check_heading" CHECK (heading IS NULL OR heading BETWEEN 0 AND 360),
  CONSTRAINT "check_speed" CHECK (speed IS NULL OR speed >= 0),
  CONSTRAINT "check_battery" CHECK (battery_level IS NULL OR battery_level BETWEEN 0 AND 100)
);

-- =============================================
-- PAYMENTS TABLE
-- =============================================
CREATE TABLE "payments" (
  "id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  "payment_id" varchar(100) UNIQUE NOT NULL DEFAULT ('PAY-' || substring(uuid_generate_v4()::text, 1, 8)),
  "customer_id" varchar(100) NOT NULL,
  "delivery_id" varchar(100),
  "package_id" varchar(100),
  "amount" decimal(10,2) NOT NULL,
  "currency" varchar(3) NOT NULL DEFAULT 'NGN',
  "payment_method" payment_method_type NOT NULL,
  "transaction_id" varchar(100) UNIQUE,
  "status" payment_status NOT NULL DEFAULT 'pending',
  "payment_date" timestamp,
  "created_at" timestamp NOT NULL DEFAULT now(),
  "updated_at" timestamp NOT NULL DEFAULT now(),
  CONSTRAINT "check_amount_positive" CHECK (amount > 0)
);

-- =============================================
-- PRICING TABLE
-- =============================================
CREATE TABLE "pricing" (
  "id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  "pricing_id" varchar(100) UNIQUE NOT NULL DEFAULT ('PRC-' || substring(uuid_generate_v4()::text, 1, 8)),
  "base_price" decimal(10,2) NOT NULL,
  "price_per_km" decimal(10,2) NOT NULL,
  "price_per_kg" decimal(10,2) NOT NULL,
  "priority_multiplier" decimal(3,2) NOT NULL,
  "zone" zone_type NOT NULL,
  "effective_from" timestamp NOT NULL,
  "effective_to" timestamp,
  "is_active" boolean DEFAULT true,
  "created_at" timestamp NOT NULL DEFAULT now(),
  "updated_at" timestamp NOT NULL DEFAULT now(),
  CONSTRAINT "check_prices_positive" CHECK (
    base_price >= 0 AND 
    price_per_km >= 0 AND 
    price_per_kg >= 0 AND 
    priority_multiplier > 0
  ),
  CONSTRAINT "check_effective_dates" CHECK (
    effective_to IS NULL OR effective_from < effective_to
  )
);

-- =============================================
-- RATINGS TABLE
-- =============================================
CREATE TABLE "ratings" (
  "id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  "rating_id" varchar(100) UNIQUE NOT NULL DEFAULT ('RAT-' || substring(uuid_generate_v4()::text, 1, 8)),
  "delivery_id" varchar(100) NOT NULL,
  "rated_by" varchar(100) NOT NULL,
  "rated_user" varchar(100) NOT NULL,
  "rating" int NOT NULL,
  "comment" text,
  "rating_type" rating_type NOT NULL,
  "created_at" timestamp NOT NULL DEFAULT now(),
  CONSTRAINT "check_rating_value" CHECK (rating BETWEEN 1 AND 5),
  CONSTRAINT "unique_delivery_rater" UNIQUE (delivery_id, rated_by),
  CONSTRAINT "check_not_self_rating" CHECK (rated_by != rated_user)
);

-- =============================================
-- NOTIFICATIONS TABLE
-- =============================================
CREATE TABLE "notifications" (
  "id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  "notification_id" varchar(100) UNIQUE NOT NULL DEFAULT ('NOTIF-' || substring(uuid_generate_v4()::text, 1, 8)),
  "user_id" varchar(100) NOT NULL,
  "notification_type" varchar(50) NOT NULL,
  "title" varchar(255) NOT NULL,
  "message" text NOT NULL,
  "reference_id" varchar(100),
  "reference_type" varchar(50),
  "is_read" boolean DEFAULT false,
  "sent_at" timestamp NOT NULL DEFAULT now(),
  "read_at" timestamp,
  "metadata" jsonb,
  "created_at" timestamp NOT NULL DEFAULT now()
);

-- =============================================
-- VEHICLE MAINTENANCE TABLE
-- =============================================
CREATE TABLE "vehicle_maintenance" (
  "id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  "maintenance_id" varchar(100) UNIQUE NOT NULL DEFAULT ('MAINT-' || substring(uuid_generate_v4()::text, 1, 8)),
  "driver_id" varchar(100) NOT NULL,
  "maintenance_type" maintenance_type NOT NULL,
  "description" text NOT NULL,
  "cost" decimal(10,2),
  "scheduled_date" timestamp,
  "completed_date" timestamp,
  "next_due_date" timestamp,
  "status" maintenance_status NOT NULL DEFAULT 'scheduled',
  "created_at" timestamp NOT NULL DEFAULT now(),
  "updated_at" timestamp NOT NULL DEFAULT now(),
  CONSTRAINT "check_cost_positive" CHECK (cost IS NULL OR cost >= 0),
  CONSTRAINT "check_completion_date" CHECK (
    scheduled_date IS NULL OR completed_date IS NULL OR 
    completed_date >= scheduled_date
  )
);

-- =============================================
-- FOREIGN KEY CONSTRAINTS (CORRECTED)
-- =============================================

-- Drivers reference Users
ALTER TABLE "drivers" 
  ADD CONSTRAINT "fk_drivers_user" 
  FOREIGN KEY ("user_id") REFERENCES "users" ("user_id") 
  ON DELETE CASCADE ON UPDATE CASCADE;

-- Customers reference Users
ALTER TABLE "customers" 
  ADD CONSTRAINT "fk_customers_user" 
  FOREIGN KEY ("user_id") REFERENCES "users" ("user_id") 
  ON DELETE CASCADE ON UPDATE CASCADE;

-- Addresses reference Users
ALTER TABLE "addresses" 
  ADD CONSTRAINT "fk_addresses_user" 
  FOREIGN KEY ("user_id") REFERENCES "users" ("user_id") 
  ON DELETE CASCADE ON UPDATE CASCADE;

-- Packages reference Customers and Addresses
ALTER TABLE "packages" 
  ADD CONSTRAINT "fk_packages_customer" 
  FOREIGN KEY ("customer_id") REFERENCES "customers" ("customer_id") 
  ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "packages" 
  ADD CONSTRAINT "fk_packages_pickup_address" 
  FOREIGN KEY ("pickup_address_id") REFERENCES "addresses" ("address_id") 
  ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "packages" 
  ADD CONSTRAINT "fk_packages_delivery_address" 
  FOREIGN KEY ("delivery_address_id") REFERENCES "addresses" ("address_id") 
  ON DELETE RESTRICT ON UPDATE CASCADE;

-- Deliveries reference Packages, Drivers, and Routes
ALTER TABLE "deliveries" 
  ADD CONSTRAINT "fk_deliveries_package" 
  FOREIGN KEY ("package_id") REFERENCES "packages" ("package_id") 
  ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "deliveries" 
  ADD CONSTRAINT "fk_deliveries_driver" 
  FOREIGN KEY ("driver_id") REFERENCES "drivers" ("driver_id") 
  ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "deliveries" 
  ADD CONSTRAINT "fk_deliveries_route" 
  FOREIGN KEY ("route_id") REFERENCES "routes" ("route_id") 
  ON DELETE SET NULL ON UPDATE CASCADE;

-- Routes reference Drivers
ALTER TABLE "routes" 
  ADD CONSTRAINT "fk_routes_driver" 
  FOREIGN KEY ("driver_id") REFERENCES "drivers" ("driver_id") 
  ON DELETE CASCADE ON UPDATE CASCADE;

-- Route Stops reference Routes, Deliveries, and Addresses
ALTER TABLE "route_stops" 
  ADD CONSTRAINT "fk_route_stops_route" 
  FOREIGN KEY ("route_id") REFERENCES "routes" ("route_id") 
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "route_stops" 
  ADD CONSTRAINT "fk_route_stops_delivery" 
  FOREIGN KEY ("delivery_id") REFERENCES "deliveries" ("delivery_id") 
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "route_stops" 
  ADD CONSTRAINT "fk_route_stops_address" 
  FOREIGN KEY ("address_id") REFERENCES "addresses" ("address_id") 
  ON DELETE RESTRICT ON UPDATE CASCADE;

-- Tracking Events reference Packages and Deliveries
ALTER TABLE "tracking_events" 
  ADD CONSTRAINT "fk_tracking_events_package" 
  FOREIGN KEY ("package_id") REFERENCES "packages" ("package_id") 
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "tracking_events" 
  ADD CONSTRAINT "fk_tracking_events_delivery" 
  FOREIGN KEY ("delivery_id") REFERENCES "deliveries" ("delivery_id") 
  ON DELETE CASCADE ON UPDATE CASCADE;

-- Driver Locations reference Drivers
ALTER TABLE "driver_locations" 
  ADD CONSTRAINT "fk_driver_locations_driver" 
  FOREIGN KEY ("driver_id") REFERENCES "drivers" ("driver_id") 
  ON DELETE CASCADE ON UPDATE CASCADE;

-- Payments reference Customers and Deliveries
ALTER TABLE "payments" 
  ADD CONSTRAINT "fk_payments_customer" 
  FOREIGN KEY ("customer_id") REFERENCES "customers" ("customer_id") 
  ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "payments" 
  ADD CONSTRAINT "fk_payments_delivery" 
  FOREIGN KEY ("delivery_id") REFERENCES "deliveries" ("delivery_id") 
  ON DELETE SET NULL ON UPDATE CASCADE;

-- Ratings reference Deliveries
ALTER TABLE "ratings" 
  ADD CONSTRAINT "fk_ratings_delivery" 
  FOREIGN KEY ("delivery_id") REFERENCES "deliveries" ("delivery_id") 
  ON DELETE CASCADE ON UPDATE CASCADE;

-- Notifications reference Users
ALTER TABLE "notifications" 
  ADD CONSTRAINT "fk_notifications_user" 
  FOREIGN KEY ("user_id") REFERENCES "users" ("user_id") 
  ON DELETE CASCADE ON UPDATE CASCADE;

-- Vehicle Maintenance reference Drivers
ALTER TABLE "vehicle_maintenance" 
  ADD CONSTRAINT "fk_vehicle_maintenance_driver" 
  FOREIGN KEY ("driver_id") REFERENCES "drivers" ("driver_id") 
  ON DELETE CASCADE ON UPDATE CASCADE;

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

-- Users indexes
CREATE INDEX "idx_users_email" ON "users" ("email");
CREATE INDEX "idx_users_role_status" ON "users" ("role", "status");
CREATE INDEX "idx_users_phone" ON "users" ("phone");

-- Drivers indexes
CREATE INDEX "idx_drivers_user_id" ON "drivers" ("user_id");
CREATE INDEX "idx_drivers_status" ON "drivers" ("status");
CREATE INDEX "idx_drivers_vehicle_status" ON "drivers" ("vehicle_type", "status");
CREATE INDEX "idx_drivers_rating" ON "drivers" ("rating" DESC);
CREATE INDEX "idx_drivers_license_expiry" ON "drivers" ("license_expiry");
CREATE INDEX "idx_drivers_available" ON "drivers" ("status", "vehicle_type") 
  WHERE status = 'online';
CREATE INDEX "idx_drivers_current_location" ON "drivers" USING GIST ("current_location");

-- Customers indexes
CREATE INDEX "idx_customers_user_id" ON "customers" ("user_id");

-- Addresses indexes
CREATE INDEX "idx_addresses_user_id" ON "addresses" ("user_id");
CREATE INDEX "idx_addresses_postal_code" ON "addresses" ("postal_code");
CREATE INDEX "idx_addresses_city_state" ON "addresses" ("city", "state");
CREATE INDEX "idx_addresses_location" ON "addresses" USING GIST ("location");
CREATE INDEX "idx_addresses_default" ON "addresses" ("user_id", "is_default") 
  WHERE is_default = true;

-- Packages indexes
CREATE INDEX "idx_packages_customer_id" ON "packages" ("customer_id");
CREATE INDEX "idx_packages_tracking_number" ON "packages" ("tracking_number");
CREATE INDEX "idx_packages_status" ON "packages" ("status");
CREATE INDEX "idx_packages_status_priority" ON "packages" ("status", "priority");
CREATE INDEX "idx_packages_created_at" ON "packages" ("created_at" DESC);
CREATE INDEX "idx_packages_pickup_address" ON "packages" ("pickup_address_id");
CREATE INDEX "idx_packages_delivery_address" ON "packages" ("delivery_address_id");
CREATE INDEX "idx_packages_pending" ON "packages" ("status", "priority", "created_at") 
  WHERE status = 'pending' AND deleted_at IS NULL;

-- Deliveries indexes
CREATE INDEX "idx_deliveries_package_id" ON "deliveries" ("package_id");
CREATE INDEX "idx_deliveries_driver_id" ON "deliveries" ("driver_id");
CREATE INDEX "idx_deliveries_route_id" ON "deliveries" ("route_id");
CREATE INDEX "idx_deliveries_status" ON "deliveries" ("delivery_status");
CREATE INDEX "idx_deliveries_driver_status" ON "deliveries" ("driver_id", "delivery_status");
CREATE INDEX "idx_deliveries_scheduled_time" ON "deliveries" ("scheduled_delivery_time");
CREATE INDEX "idx_deliveries_actual_time" ON "deliveries" ("actual_delivery_time");
CREATE INDEX "idx_deliveries_active" ON "deliveries" ("delivery_status", "driver_id") 
  WHERE delivery_status IN ('assigned', 'in_progress');

-- Routes indexes
CREATE INDEX "idx_routes_driver_id" ON "routes" ("driver_id");
CREATE INDEX "idx_routes_status" ON "routes" ("status");
CREATE INDEX "idx_routes_driver_status" ON "routes" ("driver_id", "status");
CREATE INDEX "idx_routes_started_at" ON "routes" ("started_at");
CREATE INDEX "idx_routes_completed_at" ON "routes" ("completed_at");

-- Route Stops indexes
CREATE INDEX "idx_route_stops_route_sequence" ON "route_stops" ("route_id", "stop_sequence");
CREATE INDEX "idx_route_stops_delivery_id" ON "route_stops" ("delivery_id");
CREATE INDEX "idx_route_stops_status" ON "route_stops" ("status");
CREATE INDEX "idx_route_stops_scheduled_arrival" ON "route_stops" ("scheduled_arrival");

-- Tracking Events indexes
CREATE INDEX "idx_tracking_events_package_time" ON "tracking_events" ("package_id", "occurred_at" DESC);
CREATE INDEX "idx_tracking_events_delivery_time" ON "tracking_events" ("delivery_id", "occurred_at" DESC);
CREATE INDEX "idx_tracking_events_type" ON "tracking_events" ("event_type");
CREATE INDEX "idx_tracking_events_occurred_at" ON "tracking_events" ("occurred_at" DESC);

-- Driver Locations indexes
CREATE INDEX "idx_driver_locations_driver_time" ON "driver_locations" ("driver_id", "recorded_at" DESC);
CREATE INDEX "idx_driver_locations_location" ON "driver_locations" USING GIST ("location");
CREATE INDEX "idx_driver_locations_recent" ON "driver_locations" ("driver_id", "recorded_at" DESC) 
  WHERE recorded_at > now() - interval '1 hour';

-- Payments indexes
CREATE INDEX "idx_payments_customer_id" ON "payments" ("customer_id");
CREATE INDEX "idx_payments_delivery_id" ON "payments" ("delivery_id");
CREATE INDEX "idx_payments_status" ON "payments" ("status");
CREATE INDEX "idx_payments_transaction_id" ON "payments" ("transaction_id");
CREATE INDEX "idx_payments_date" ON "payments" ("payment_date" DESC);

-- Pricing indexes
CREATE INDEX "idx_pricing_zone_effective" ON "pricing" ("zone", "effective_from");
CREATE INDEX "idx_pricing_effective_dates" ON "pricing" ("effective_from", "effective_to");
CREATE INDEX "idx_pricing_active" ON "pricing" ("zone", "is_active") 
  WHERE is_active = true AND (effective_to IS NULL OR effective_to > now());

-- Ratings indexes
CREATE INDEX "idx_ratings_delivery_id" ON "ratings" ("delivery_id");
CREATE INDEX "idx_ratings_rated_user" ON "ratings" ("rated_user");
CREATE INDEX "idx_ratings_type_user" ON "ratings" ("rating_type", "rated_user");
CREATE INDEX "idx_ratings_created_at" ON "ratings" ("created_at" DESC);

-- Notifications indexes
CREATE INDEX "idx_notifications_user_read" ON "notifications" ("user_id", "is_read");
CREATE INDEX "idx_notifications_user_sent" ON "notifications" ("user_id", "sent_at" DESC);
CREATE INDEX "idx_notifications_type" ON "notifications" ("notification_type");
CREATE INDEX "idx_notifications_reference" ON "notifications" ("reference_id", "reference_type");
CREATE INDEX "idx_notifications_unread" ON "notifications" ("user_id", "sent_at" DESC) 
  WHERE is_read = false;

-- Vehicle Maintenance indexes
CREATE INDEX "idx_vehicle_maintenance_driver_id" ON "vehicle_maintenance" ("driver_id");
CREATE INDEX "idx_vehicle_maintenance_status" ON "vehicle_maintenance" ("status");
CREATE INDEX "idx_vehicle_maintenance_next_due" ON "vehicle_maintenance" ("next_due_date");
CREATE INDEX "idx_vehicle_maintenance_driver_status" ON "vehicle_maintenance" ("driver_id", "status");
CREATE INDEX "idx_vehicle_maintenance_overdue" ON "vehicle_maintenance" ("driver_id", "next_due_date") 
  WHERE status = 'scheduled' AND next_due_date < now();

-- =============================================
-- TRIGGERS FOR AUTO-UPDATING FIELDS
-- =============================================

-- Update updated_at timestamp automatically
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- Apply trigger to all tables with updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON "users"
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_drivers_updated_at BEFORE UPDATE ON "drivers"
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON "customers"
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_addresses_updated_at BEFORE UPDATE ON "addresses"
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_packages_updated_at BEFORE UPDATE ON "packages"
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_deliveries_updated_at BEFORE UPDATE ON "deliveries"
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_routes_updated_at BEFORE UPDATE ON "routes"
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_route_stops_updated_at BEFORE UPDATE ON "route_stops"
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON "payments"
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pricing_updated_at BEFORE UPDATE ON "pricing"
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vehicle_maintenance_updated_at BEFORE UPDATE ON "vehicle_maintenance"
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- AUTO-UPDATE DRIVER RATING TRIGGER
-- =============================================

CREATE OR REPLACE FUNCTION update_driver_rating()
RETURNS TRIGGER AS $
DECLARE
    v_driver_id varchar(100);
BEGIN
    -- Get driver_id from user_id
    SELECT d.driver_id INTO v_driver_id
    FROM drivers d
    INNER JOIN users u ON d.user_id = u.user_id
    WHERE u.user_id = NEW.rated_user;
    
    -- Update driver's average rating
    IF v_driver_id IS NOT NULL THEN
        UPDATE drivers 
        SET rating = (
            SELECT COALESCE(ROUND(AVG(rating)::numeric, 2), 5.0)
            FROM ratings 
            WHERE rated_user = NEW.rated_user 
            AND rating_type = 'driver_rating'
        )
        WHERE driver_id = v_driver_id;
    END IF;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_driver_rating
AFTER INSERT ON ratings
FOR EACH ROW
WHEN (NEW.rating_type = 'driver_rating')
EXECUTE FUNCTION update_driver_rating();

-- =============================================
-- AUTO-SYNC GEOGRAPHY COLUMNS TRIGGER
-- =============================================

-- For addresses
CREATE OR REPLACE FUNCTION sync_address_location()
RETURNS TRIGGER AS $
BEGIN
    IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
        NEW.location = ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
    END IF;
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_sync_address_location
BEFORE INSERT OR UPDATE ON "addresses"
FOR EACH ROW
EXECUTE FUNCTION sync_address_location();

-- For driver_locations
CREATE OR REPLACE FUNCTION sync_driver_location()
RETURNS TRIGGER AS $
BEGIN
    NEW.location = ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_sync_driver_location
BEFORE INSERT OR UPDATE ON "driver_locations"
FOR EACH ROW
EXECUTE FUNCTION sync_driver_location();

-- For drivers current_location
CREATE OR REPLACE FUNCTION sync_driver_current_location()
RETURNS TRIGGER AS $
BEGIN
    IF NEW.current_latitude IS NOT NULL AND NEW.current_longitude IS NOT NULL THEN
        NEW.current_location = ST_SetSRID(ST_MakePoint(NEW.current_longitude, NEW.current_latitude), 4326)::geography;
    END IF;
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_sync_driver_current_location
BEFORE INSERT OR UPDATE ON "drivers"
FOR EACH ROW
EXECUTE FUNCTION sync_driver_current_location();

-- For tracking_events
CREATE OR REPLACE FUNCTION sync_tracking_event_location()
RETURNS TRIGGER AS $
BEGIN
    IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
        NEW.location_point = ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
    END IF;
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_sync_tracking_event_location
BEFORE INSERT OR UPDATE ON "tracking_events"
FOR EACH ROW
EXECUTE FUNCTION sync_tracking_event_location();

-- =============================================
-- AUTO-CREATE TRACKING EVENT ON STATUS CHANGE
-- =============================================

CREATE OR REPLACE FUNCTION create_tracking_event_on_status_change()
RETURNS TRIGGER AS $
BEGIN
    -- Only create event if status actually changed
    IF (TG_OP = 'INSERT' OR OLD.status IS DISTINCT FROM NEW.status) THEN
        INSERT INTO tracking_events (
            package_id,
            delivery_id,
            event_type,
            event_description,
            occurred_at
        )
        SELECT 
            NEW.package_id,
            d.delivery_id,
            NEW.status::text::event_type,
            CASE NEW.status
                WHEN 'pending' THEN 'Package created and awaiting assignment'
                WHEN 'assigned' THEN 'Package assigned to driver'
                WHEN 'picked_up' THEN 'Package picked up by driver'
                WHEN 'in_transit' THEN 'Package in transit'
                WHEN 'out_for_delivery' THEN 'Package out for delivery'
                WHEN 'delivered' THEN 'Package successfully delivered'
                WHEN 'failed' THEN 'Delivery failed'
                WHEN 'cancelled' THEN 'Package delivery cancelled'
                ELSE 'Status updated'
            END,
            now()
        FROM deliveries d
        WHERE d.package_id = NEW.package_id
        LIMIT 1;
    END IF;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_create_tracking_event
AFTER INSERT OR UPDATE ON "packages"
FOR EACH ROW
EXECUTE FUNCTION create_tracking_event_on_status_change();

-- =============================================
-- AUTO-UPDATE CUSTOMER TOTALS
-- =============================================

CREATE OR REPLACE FUNCTION update_customer_totals()
RETURNS TRIGGER AS $
BEGIN
    UPDATE customers
    SET 
        total_orders = (
            SELECT COUNT(*) 
            FROM packages 
            WHERE customer_id = NEW.customer_id
        ),
        total_spent = (
            SELECT COALESCE(SUM(p.amount), 0)
            FROM payments p
            WHERE p.customer_id = NEW.customer_id
            AND p.status = 'completed'
        )
    WHERE customer_id = NEW.customer_id;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_customer_totals_on_package
AFTER INSERT ON "packages"
FOR EACH ROW
EXECUTE FUNCTION update_customer_totals();

CREATE TRIGGER trigger_update_customer_totals_on_payment
AFTER INSERT OR UPDATE ON "payments"
FOR EACH ROW
WHEN (NEW.status = 'completed')
EXECUTE FUNCTION update_customer_totals();

-- =============================================
-- AUTO-UPDATE DRIVER DELIVERY COUNTS
-- =============================================

CREATE OR REPLACE FUNCTION update_driver_delivery_counts()
RETURNS TRIGGER AS $
BEGIN
    IF NEW.delivery_status = 'completed' AND (OLD.delivery_status IS NULL OR OLD.delivery_status != 'completed') THEN
        UPDATE drivers
        SET 
            total_deliveries = total_deliveries + 1,
            completed_deliveries = completed_deliveries + 1
        WHERE driver_id = NEW.driver_id;
    END IF;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_driver_delivery_counts
AFTER UPDATE ON "deliveries"
FOR EACH ROW
EXECUTE FUNCTION update_driver_delivery_counts();

-- =============================================
-- VIEWS FOR COMMON QUERIES
-- =============================================

-- Active deliveries with full details
CREATE OR REPLACE VIEW active_deliveries_view AS
SELECT 
    d.delivery_id,
    d.delivery_status,
    p.package_id,
    p.tracking_number,
    p.description AS package_description,
    p.weight,
    p.priority,
    p.status AS package_status,
    dr.driver_id,
    u.first_name || ' ' || u.last_name AS driver_name,
    dr.vehicle_type,
    dr.vehicle_plate,
    c.customer_id,
    cu.first_name || ' ' || cu.last_name AS customer_name,
    cu.email AS customer_email,
    pa.street_address AS pickup_address,
    pa.city AS pickup_city,
    da.street_address AS delivery_address,
    da.city AS delivery_city,
    d.scheduled_delivery_time,
    d.estimated_delivery_time,
    d.distance_km,
    d.created_at AS delivery_created_at
FROM deliveries d
INNER JOIN packages p ON d.package_id = p.package_id
LEFT JOIN drivers dr ON d.driver_id = dr.driver_id
LEFT JOIN users u ON dr.user_id = u.user_id
INNER JOIN customers c ON p.customer_id = c.customer_id
INNER JOIN users cu ON c.user_id = cu.user_id
INNER JOIN addresses pa ON p.pickup_address_id = pa.address_id
INNER JOIN addresses da ON p.delivery_address_id = da.address_id
WHERE d.delivery_status IN ('assigned', 'in_progress')
AND d.deleted_at IS NULL
AND p.deleted_at IS NULL;

-- Driver performance metrics
CREATE OR REPLACE VIEW driver_performance_view AS
SELECT 
    dr.driver_id,
    u.first_name || ' ' || u.last_name AS driver_name,
    dr.vehicle_type,
    dr.status,
    dr.rating,
    dr.total_deliveries,
    dr.completed_deliveries,
    CASE 
        WHEN dr.total_deliveries > 0 THEN 
            ROUND((dr.completed_deliveries::decimal / dr.total_deliveries * 100), 2)
        ELSE 0 
    END AS completion_rate,
    COUNT(DISTINCT CASE WHEN d.delivery_status = 'in_progress' THEN d.delivery_id END) AS active_deliveries,
    AVG(CASE WHEN d.delivery_status = 'completed' THEN d.duration_minutes END) AS avg_delivery_time_minutes,
    SUM(CASE WHEN d.delivery_status = 'completed' THEN d.distance_km ELSE 0 END) AS total_distance_km,
    COUNT(CASE WHEN d.is_delayed = true THEN 1 END) AS delayed_deliveries,
    dr.created_at AS driver_since
FROM drivers dr
INNER JOIN users u ON dr.user_id = u.user_id
LEFT JOIN deliveries d ON dr.driver_id = d.driver_id
GROUP BY dr.driver_id, u.first_name, u.last_name, dr.vehicle_type, dr.status, 
         dr.rating, dr.total_deliveries, dr.completed_deliveries, dr.created_at;

-- Package tracking summary
CREATE OR REPLACE VIEW package_tracking_summary AS
SELECT 
    p.package_id,
    p.tracking_number,
    p.status,
    p.priority,
    c.customer_id,
    u.first_name || ' ' || u.last_name AS customer_name,
    d.delivery_id,
    d.driver_id,
    du.first_name || ' ' || du.last_name AS driver_name,
    d.delivery_status,
    d.estimated_delivery_time,
    COUNT(te.event_id) AS total_events,
    MAX(te.occurred_at) AS last_event_time,
    p.created_at
FROM packages p
INNER JOIN customers c ON p.customer_id = c.customer_id
INNER JOIN users u ON c.user_id = u.user_id
LEFT JOIN deliveries d ON p.package_id = d.package_id
LEFT JOIN drivers dr ON d.driver_id = dr.driver_id
LEFT JOIN users du ON dr.user_id = du.user_id
LEFT JOIN tracking_events te ON p.package_id = te.package_id
WHERE p.deleted_at IS NULL
GROUP BY p.package_id, p.tracking_number, p.status, p.priority, c.customer_id, 
         u.first_name, u.last_name, d.delivery_id, d.driver_id, du.first_name, 
         du.last_name, d.delivery_status, d.estimated_delivery_time, p.created_at;

-- =============================================
-- USEFUL FUNCTIONS
-- =============================================

-- Calculate distance between two points (Haversine formula)
CREATE OR REPLACE FUNCTION calculate_distance_km(
    lat1 decimal, lon1 decimal,
    lat2 decimal, lon2 decimal
)
RETURNS decimal AS $
DECLARE
    R decimal := 6371; -- Earth's radius in km
    dLat decimal;
    dLon decimal;
    a decimal;
    c decimal;
BEGIN
    dLat := radians(lat2 - lat1);
    dLon := radians(lon2 - lon1);
    
    a := sin(dLat/2) * sin(dLat/2) +
         cos(radians(lat1)) * cos(radians(lat2)) *
         sin(dLon/2) * sin(dLon/2);
    
    c := 2 * atan2(sqrt(a), sqrt(1-a));
    
    RETURN R * c;
END;
$ LANGUAGE plpgsql IMMUTABLE;

-- Get active pricing for a zone
CREATE OR REPLACE FUNCTION get_active_pricing(p_zone zone_type)
RETURNS TABLE (
    pricing_id varchar,
    base_price decimal,
    price_per_km decimal,
    price_per_kg decimal,
    priority_multiplier decimal
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        pr.pricing_id,
        pr.base_price,
        pr.price_per_km,
        pr.price_per_kg,
        pr.priority_multiplier
    FROM pricing pr
    WHERE pr.zone = p_zone
    AND pr.is_active = true
    AND pr.effective_from <= now()
    AND (pr.effective_to IS NULL OR pr.effective_to > now())
    ORDER BY pr.effective_from DESC
    LIMIT 1;
END;
$ LANGUAGE plpgsql;

-- =============================================
-- SAMPLE DATA INSERT (Optional - for testing)
-- =============================================

-- Insert sample admin user
INSERT INTO users (user_id, first_name, last_name, email, password, phone, role, status)
VALUES 
('USR-ADMIN01', 'Admin', 'User', 'admin@streamfleet.com', 
 '$2a$10$YourHashedPasswordHere', '+2348012345678', 'admin', 'active');

COMMENT ON TABLE users IS 'Base table for all system users';
COMMENT ON TABLE drivers IS 'Driver-specific information and metrics';
COMMENT ON TABLE customers IS 'Customer profiles and business information';
COMMENT ON TABLE packages IS 'Package/shipment details';
COMMENT ON TABLE deliveries IS 'Delivery assignments and tracking';
COMMENT ON TABLE routes IS 'Optimized delivery routes for drivers';
COMMENT ON TABLE tracking_events IS 'Audit trail of package journey';
COMMENT ON TABLE driver_locations IS 'Real-time driver GPS location history';

-- =============================================
-- SCHEMA VERSION TRACKING
-- =============================================

CREATE TABLE IF NOT EXISTS schema_version (
    version varchar(50) PRIMARY KEY,
    applied_at timestamp NOT NULL DEFAULT now(),
    description text
);

INSERT INTO schema_version (version, description)
VALUES ('1.0.0', 'Initial StreamFleet schema with corrected relationships and PostGIS support');