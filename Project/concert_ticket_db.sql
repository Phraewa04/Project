-- ============================================================
-- DDL CREATE TABLES - Concert Ticket Reservation System
-- ============================================================

-- 1. ตารางผู้ใช้งาน
CREATE TABLE users (
    user_id VARCHAR(8) PRIMARY KEY,
    full_name VARCHAR(60) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(15) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'CUSTOMER' CHECK (role IN ('CUSTOMER', 'ADMIN', 'STAFF')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. ตารางสถานที่จัดงาน
CREATE TABLE venues (
    venue_id SERIAL PRIMARY KEY,
    venue_name VARCHAR(60) NOT NULL,
    location TEXT NOT NULL,
    capacity INT NOT NULL
);

-- 3. ตารางคอนเสิร์ต
CREATE TABLE concerts (
    concert_id SERIAL PRIMARY KEY,
    venue_id INT NOT NULL,
    concert_name VARCHAR(60) NOT NULL,
    artist_name VARCHAR(60) NOT NULL,
    show_date TIMESTAMP NOT NULL,
    booking_start_time TIMESTAMP NOT NULL,
    status VARCHAR(20) DEFAULT 'UPCOMING' CHECK (status IN ('UPCOMING', 'OPEN', 'ENDED', 'CANCELLED')),
    CONSTRAINT fk_concert_venue FOREIGN KEY (venue_id) REFERENCES venues(venue_id) ON DELETE RESTRICT
);

-- 4. ตารางผังโซนที่นั่ง
CREATE TABLE zones (
    zone_id SERIAL PRIMARY KEY,
    concert_id INT NOT NULL,
    zone_name VARCHAR(60) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    total_seats INT NOT NULL,
    CONSTRAINT fk_zone_concert FOREIGN KEY (concert_id) REFERENCES concerts(concert_id) ON DELETE CASCADE
);

-- 5. ตารางที่นั่ง (Real-time Status)
CREATE TABLE seats (
    seat_id SERIAL PRIMARY KEY,
    zone_id INT NOT NULL,
    seat_number VARCHAR(10) NOT NULL,
    status VARCHAR(20) DEFAULT 'AVAILABLE' CHECK (status IN ('AVAILABLE', 'LOCKED', 'BOOKED')),
    locked_by_user_id VARCHAR(8),
    lock_expires_at TIMESTAMP,
    CONSTRAINT fk_seat_zone FOREIGN KEY (zone_id) REFERENCES zones(zone_id) ON DELETE CASCADE,
    CONSTRAINT fk_seat_locked_user FOREIGN KEY (locked_by_user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    CONSTRAINT uq_zone_seat UNIQUE (zone_id, seat_number)
);

-- 6. ตารางยืนยัน OTP
CREATE TABLE otp_verifications (
    otp_id SERIAL PRIMARY KEY,
    user_id VARCHAR(8) NOT NULL,
    otp_code VARCHAR(6) NOT NULL,
    purpose VARCHAR(20) NOT NULL CHECK (purpose IN ('LOGIN', 'BOOKING', 'REGISTER')),
    is_used BOOLEAN DEFAULT FALSE,
    attempts INT DEFAULT 0,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_otp_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- 7. ตารางใบคำสั่งจองตั๋ว
CREATE TABLE bookings (
    booking_id SERIAL PRIMARY KEY,
    user_id VARCHAR(8) NOT NULL,
    booking_ref VARCHAR(20) NOT NULL UNIQUE,
    total_amount DECIMAL(10,2) NOT NULL,
    booking_status VARCHAR(20) DEFAULT 'PENDING' CHECK (booking_status IN ('PENDING', 'PAID', 'EXPIRED', 'CANCELLED')),
    qr_code_data TEXT,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_booking_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE RESTRICT
);

-- 8. ตารางรายละเอียดที่นั่งในใบจอง
CREATE TABLE booking_details (
    detail_id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL,
    seat_id INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_detail_booking FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE CASCADE,
    CONSTRAINT fk_detail_seat FOREIGN KEY (seat_id) REFERENCES seats(seat_id) ON DELETE RESTRICT
);

-- 9. ตารางการชำระเงิน
CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL,
    payment_method VARCHAR(30) NOT NULL CHECK (payment_method IN ('PROMPTPAY', 'CREDIT_CARD', 'BANK_TRANSFER')),
    amount DECIMAL(10,2) NOT NULL,
    payment_status VARCHAR(20) DEFAULT 'PENDING' CHECK (payment_status IN ('PENDING', 'COMPLETED', 'FAILED', 'REFUNDED')),
    transaction_ref VARCHAR(100),
    paid_at TIMESTAMP,
    CONSTRAINT fk_payment_booking FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE CASCADE
);

-- 10. ตารางบันทึกความปลอดภัยหลังบ้าน (Security Audit Logs)
CREATE TABLE audit_logs (
    log_id SERIAL PRIMARY KEY,
    user_id VARCHAR(8),
    action VARCHAR(100) NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
);