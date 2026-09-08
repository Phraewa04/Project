CREATE TABLE IF NOT EXISTS "users" (
	"user_id" VARCHAR(8),
	"full_name" VARCHAR(60) NOT NULL,
	"email" VARCHAR(100) NOT NULL UNIQUE,
	"phone" VARCHAR(15) NOT NULL,
	"password_hash" VARCHAR(255) NOT NULL,
	"role" VARCHAR(20) DEFAULT 'CUSTOMER' CHECK("[object Object]" IN CUSTOMER AND ADMIN AND STAFF),
	"created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY("user_id")
);

CREATE TABLE IF NOT EXISTS "venues" (
	"venue_id" SERIAL,
	"venue_name" VARCHAR(60) NOT NULL,
	"location" TEXT NOT NULL,
	"capacity" INTEGER NOT NULL,
	PRIMARY KEY("venue_id")
);

CREATE TABLE IF NOT EXISTS "concerts" (
	"concert_id" SERIAL,
	"venue_id" INTEGER NOT NULL,
	"concert_name" VARCHAR(60) NOT NULL,
	"artist_name" VARCHAR(60) NOT NULL,
	"show_date" TIMESTAMP NOT NULL,
	"booking_start_time" TIMESTAMP NOT NULL,
	"status" VARCHAR(20) DEFAULT 'UPCOMING' CHECK("[object Object]" IN UPCOMING AND OPEN AND ENDED AND CANCELLED),
	PRIMARY KEY("concert_id")
);

CREATE TABLE IF NOT EXISTS "zones" (
	"zone_id" SERIAL,
	"concert_id" INTEGER NOT NULL,
	"zone_name" VARCHAR(60) NOT NULL,
	"price" DECIMAL(10,2) NOT NULL,
	"total_seats" INTEGER NOT NULL,
	PRIMARY KEY("zone_id")
);

CREATE TABLE IF NOT EXISTS "seats" (
	"seat_id" SERIAL,
	"zone_id" INTEGER NOT NULL,
	"seat_number" VARCHAR(10) NOT NULL,
	"status" VARCHAR(20) DEFAULT 'AVAILABLE' CHECK("[object Object]" IN AVAILABLE AND LOCKED AND BOOKED),
	"locked_by_user_id" VARCHAR(8),
	"lock_expires_at" TIMESTAMP,
	PRIMARY KEY("seat_id"),
	CONSTRAINT "uq_zone_seat" UNIQUE ("zone_id", "seat_number")
);

CREATE TABLE IF NOT EXISTS "otp_verifications" (
	"otp_id" SERIAL,
	"user_id" VARCHAR(8) NOT NULL,
	"otp_code" VARCHAR(6) NOT NULL,
	"purpose" VARCHAR(20) NOT NULL CHECK("[object Object]" IN LOGIN AND BOOKING AND REGISTER),
	"is_used" BOOLEAN DEFAULT false,
	"attempts" INTEGER DEFAULT 0,
	"expires_at" TIMESTAMP NOT NULL,
	"created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY("otp_id")
);

CREATE TABLE IF NOT EXISTS "bookings" (
	"booking_id" SERIAL,
	"user_id" VARCHAR(8) NOT NULL,
	"booking_ref" VARCHAR(20) NOT NULL UNIQUE,
	"total_amount" DECIMAL(10,2) NOT NULL,
	"booking_status" VARCHAR(20) DEFAULT 'PENDING' CHECK("[object Object]" IN PENDING AND PAID AND EXPIRED AND CANCELLED),
	"qr_code_data" TEXT,
	"expires_at" TIMESTAMP NOT NULL,
	"created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY("booking_id")
);

CREATE TABLE IF NOT EXISTS "booking_details" (
	"detail_id" SERIAL,
	"booking_id" INTEGER NOT NULL,
	"seat_id" INTEGER NOT NULL,
	"unit_price" DECIMAL(10,2) NOT NULL,
	PRIMARY KEY("detail_id")
);

CREATE TABLE IF NOT EXISTS "payments" (
	"payment_id" SERIAL,
	"booking_id" INTEGER NOT NULL,
	"payment_method" VARCHAR(30) NOT NULL CHECK("[object Object]" IN PROMPTPAY AND CREDIT_CARD AND BANK_TRANSFER),
	"amount" DECIMAL(10,2) NOT NULL,
	"payment_status" VARCHAR(20) DEFAULT 'PENDING' CHECK("[object Object]" IN PENDING AND COMPLETED AND FAILED AND REFUNDED),
	"transaction_ref" VARCHAR(100),
	"paid_at" TIMESTAMP,
	PRIMARY KEY("payment_id")
);

CREATE TABLE IF NOT EXISTS "audit_logs" (
	"log_id" SERIAL,
	"user_id" VARCHAR(8),
	"action" VARCHAR(100) NOT NULL,
	"ip_address" VARCHAR(45) NOT NULL,
	"user_agent" TEXT,
	"created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY("log_id")
);

ALTER TABLE "concerts"
ADD FOREIGN KEY("venue_id") REFERENCES "venues"("venue_id")
ON UPDATE NO ACTION ON DELETE RESTRICT;
ALTER TABLE "zones"
ADD FOREIGN KEY("concert_id") REFERENCES "concerts"("concert_id")
ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE "seats"
ADD FOREIGN KEY("zone_id") REFERENCES "zones"("zone_id")
ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE "seats"
ADD FOREIGN KEY("locked_by_user_id") REFERENCES "users"("user_id")
ON UPDATE NO ACTION ON DELETE SET NULL;
ALTER TABLE "otp_verifications"
ADD FOREIGN KEY("user_id") REFERENCES "users"("user_id")
ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE "bookings"
ADD FOREIGN KEY("user_id") REFERENCES "users"("user_id")
ON UPDATE NO ACTION ON DELETE RESTRICT;
ALTER TABLE "booking_details"
ADD FOREIGN KEY("booking_id") REFERENCES "bookings"("booking_id")
ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE "booking_details"
ADD FOREIGN KEY("seat_id") REFERENCES "seats"("seat_id")
ON UPDATE NO ACTION ON DELETE RESTRICT;
ALTER TABLE "payments"
ADD FOREIGN KEY("booking_id") REFERENCES "bookings"("booking_id")
ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE "audit_logs"
ADD FOREIGN KEY("user_id") REFERENCES "users"("user_id")
ON UPDATE NO ACTION ON DELETE SET NULL;