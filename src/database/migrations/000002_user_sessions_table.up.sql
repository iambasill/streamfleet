


CREATE TABLE "user_sessions" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "user_id" VARCHAR(255) NOT NULL ,
    "session_token" VARCHAR(255) NOT NULL UNIQUE,
    "status" VARCHAR(50) NOT NULL DEFAULT 'active',
  "created_at" timestamp NOT NULL DEFAULT now(),
  "expires_at" timestamp NOT NULL);


CREATE INDEX "idx_user_sessions_user_id" ON "user_sessions" ("user_id");
