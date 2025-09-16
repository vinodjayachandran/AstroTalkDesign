-- AstroTalk Database Schema
-- PostgreSQL Database Schema for User Management and Consultation Booking

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create ENUM types
CREATE TYPE user_type_enum AS ENUM ('user', 'astrologer', 'admin');
CREATE TYPE profile_status_enum AS ENUM ('pending', 'approved', 'rejected', 'suspended');
CREATE TYPE consultation_status_enum AS ENUM ('scheduled', 'in_progress', 'completed', 'cancelled', 'no_show');
CREATE TYPE consultation_type_enum AS ENUM ('call', 'video', 'chat', 'email');
CREATE TYPE payment_status_enum AS ENUM ('pending', 'completed', 'failed', 'refunded');
CREATE TYPE gender_enum AS ENUM ('male', 'female', 'other', 'prefer_not_to_say');
CREATE TYPE kyc_status_enum AS ENUM ('not_started', 'in_progress', 'completed', 'failed', 'rejected');

-- Users table (synced with AWS Cognito)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cognito_user_id VARCHAR(255) UNIQUE NOT NULL, -- AWS Cognito User ID
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255),
    user_type user_type_enum NOT NULL DEFAULT 'user',
    profile_status profile_status_enum NOT NULL DEFAULT 'pending',
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    date_of_birth DATE,
    gender gender_enum,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100) DEFAULT 'India',
    profile_picture_url TEXT,
    is_phone_verified BOOLEAN DEFAULT FALSE,
    is_email_verified BOOLEAN DEFAULT FALSE,
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Indexes
    CONSTRAINT users_phone_number_check CHECK (phone_number ~ '^\+?[1-9]\d{1,14}$'),
    CONSTRAINT users_email_check CHECK (email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Astrologer profiles (additional fields for astrologers)
CREATE TABLE astrologer_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    display_name VARCHAR(150) NOT NULL,
    bio TEXT,
    experience_years INTEGER DEFAULT 0,
    languages TEXT[], -- Array of languages spoken
    specializations TEXT[], -- Array of specializations (vedic, tarot, numerology, etc.)
    education TEXT,
    certifications TEXT[],
    consultation_rate_per_minute DECIMAL(8,2) DEFAULT 0.00,
    availability_status BOOLEAN DEFAULT TRUE,
    total_consultations INTEGER DEFAULT 0,
    average_rating DECIMAL(3,2) DEFAULT 0.00,
    total_ratings INTEGER DEFAULT 0,
    -- Verification documents
    verification_documents JSONB, -- Store document URLs and types
    verification_status profile_status_enum DEFAULT 'pending',
    verified_at TIMESTAMP WITH TIME ZONE,
    verified_by UUID REFERENCES users(id),
    
    -- KYC Integration with Digio
    kyc_status kyc_status_enum DEFAULT 'not_started',
    kyc_request_id VARCHAR(255), -- Digio KYC request ID
    kyc_reference_id VARCHAR(255), -- Internal reference ID for KYC
    kyc_initiated_at TIMESTAMP WITH TIME ZONE,
    kyc_completed_at TIMESTAMP WITH TIME ZONE,
    kyc_digio_response JSONB, -- Store Digio's complete KYC response
    kyc_documents JSONB, -- Store document references from KYC
    kyc_rejection_reason TEXT, -- Reason for KYC rejection if any
    kyc_retry_count INTEGER DEFAULT 0, -- Number of KYC retry attempts
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT astrologer_profiles_rate_check CHECK (consultation_rate_per_minute >= 0),
    CONSTRAINT astrologer_profiles_experience_check CHECK (experience_years >= 0),
    CONSTRAINT astrologer_profiles_rating_check CHECK (average_rating >= 0 AND average_rating <= 5),
    CONSTRAINT astrologer_profiles_kyc_retry_check CHECK (kyc_retry_count >= 0)
);

-- Astrologer availability schedule
CREATE TABLE astrologer_availability (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    astrologer_id UUID NOT NULL REFERENCES astrologer_profiles(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6), -- 0 = Sunday
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    timezone VARCHAR(50) DEFAULT 'Asia/Kolkata',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT availability_time_check CHECK (start_time < end_time),
    UNIQUE(astrologer_id, day_of_week, start_time, end_time)
);

-- Consultation bookings
CREATE TABLE consultations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id VARCHAR(20) UNIQUE NOT NULL, -- Human readable booking ID
    user_id UUID NOT NULL REFERENCES users(id),
    astrologer_id UUID NOT NULL REFERENCES astrologer_profiles(id),
    consultation_type consultation_type_enum NOT NULL,
    status consultation_status_enum NOT NULL DEFAULT 'scheduled',
    
    -- Scheduling
    scheduled_at TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_minutes INTEGER NOT NULL DEFAULT 30,
    timezone VARCHAR(50) DEFAULT 'Asia/Kolkata',
    
    -- Pricing
    rate_per_minute DECIMAL(8,2) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    discount_amount DECIMAL(10,2) DEFAULT 0.00,
    final_amount DECIMAL(10,2) NOT NULL,
    
    -- Session details
    session_url TEXT, -- For video/call consultations
    session_id VARCHAR(255), -- Third-party session ID (Agora, Twilio, etc.)
    chat_room_id UUID, -- For chat consultations
    
    -- Metadata
    user_question TEXT,
    astrologer_notes TEXT,
    consultation_summary TEXT,
    
    -- Timing
    started_at TIMESTAMP WITH TIME ZONE,
    ended_at TIMESTAMP WITH TIME ZONE,
    actual_duration_minutes INTEGER,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT consultations_duration_check CHECK (duration_minutes > 0),
    CONSTRAINT consultations_amount_check CHECK (total_amount >= 0 AND final_amount >= 0),
    CONSTRAINT consultations_booking_id_format CHECK (booking_id ~ '^AT[0-9]{8}$')
);

-- Payment transactions
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    consultation_id UUID NOT NULL REFERENCES consultations(id),
    payment_gateway VARCHAR(50) NOT NULL, -- razorpay, stripe, paytm, etc.
    gateway_transaction_id VARCHAR(255),
    gateway_payment_id VARCHAR(255),
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'INR',
    status payment_status_enum NOT NULL DEFAULT 'pending',
    payment_method VARCHAR(50), -- card, upi, netbanking, wallet
    
    -- Gateway response
    gateway_response JSONB,
    failure_reason TEXT,
    
    -- Refund details
    refund_amount DECIMAL(10,2) DEFAULT 0.00,
    refund_reason TEXT,
    refunded_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Reviews and ratings
CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    consultation_id UUID NOT NULL REFERENCES consultations(id),
    user_id UUID NOT NULL REFERENCES users(id),
    astrologer_id UUID NOT NULL REFERENCES astrologer_profiles(id),
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    is_public BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE, -- Verified purchase
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(consultation_id) -- One review per consultation
);

-- Chat messages (for chat consultations)
CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    consultation_id UUID NOT NULL REFERENCES consultations(id),
    sender_id UUID NOT NULL REFERENCES users(id),
    message_text TEXT,
    message_type VARCHAR(20) DEFAULT 'text', -- text, image, audio, file
    file_url TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Wallet and credits system
CREATE TABLE user_wallets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    balance DECIMAL(10,2) DEFAULT 0.00,
    total_credited DECIMAL(10,2) DEFAULT 0.00,
    total_debited DECIMAL(10,2) DEFAULT 0.00,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT wallet_balance_check CHECK (balance >= 0),
    UNIQUE(user_id)
);

-- Wallet transactions
CREATE TABLE wallet_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    wallet_id UUID NOT NULL REFERENCES user_wallets(id),
    transaction_type VARCHAR(20) NOT NULL, -- credit, debit, refund
    amount DECIMAL(10,2) NOT NULL,
    balance_after DECIMAL(10,2) NOT NULL,
    reference_type VARCHAR(50), -- consultation, topup, refund, bonus
    reference_id UUID, -- consultation_id or payment_id
    description TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Promotional codes and discounts
CREATE TABLE promo_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    discount_type VARCHAR(20) NOT NULL, -- percentage, fixed
    discount_value DECIMAL(8,2) NOT NULL,
    max_discount_amount DECIMAL(8,2),
    min_order_amount DECIMAL(8,2) DEFAULT 0.00,
    usage_limit INTEGER,
    used_count INTEGER DEFAULT 0,
    user_limit INTEGER DEFAULT 1, -- Max uses per user
    is_active BOOLEAN DEFAULT TRUE,
    valid_from TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    valid_until TIMESTAMP WITH TIME ZONE,
    applicable_user_type user_type_enum DEFAULT 'user',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Promo code usage tracking
CREATE TABLE promo_code_usage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    promo_code_id UUID NOT NULL REFERENCES promo_codes(id),
    user_id UUID NOT NULL REFERENCES users(id),
    consultation_id UUID REFERENCES consultations(id),
    discount_amount DECIMAL(8,2) NOT NULL,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(promo_code_id, user_id, consultation_id)
);

-- KYC audit logs for tracking KYC process events
CREATE TABLE kyc_audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    astrologer_profile_id UUID NOT NULL REFERENCES astrologer_profiles(id) ON DELETE CASCADE,
    kyc_request_id VARCHAR(255), -- Digio KYC request ID
    event_type VARCHAR(50) NOT NULL, -- initiated, completed, failed, webhook_received, etc.
    event_status VARCHAR(50), -- success, failure, pending
    digio_webhook_data JSONB, -- Raw webhook data from Digio
    api_request_data JSONB, -- Request data sent to Digio
    api_response_data JSONB, -- Response data from Digio
    error_message TEXT, -- Error details if any
    user_agent TEXT, -- User agent for web-based KYC
    ip_address INET, -- IP address for security tracking
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX idx_users_cognito_user_id ON users(cognito_user_id);
CREATE INDEX idx_users_phone_number ON users(phone_number);
CREATE INDEX idx_users_user_type ON users(user_type);
CREATE INDEX idx_users_profile_status ON users(profile_status);

CREATE INDEX idx_astrologer_profiles_user_id ON astrologer_profiles(user_id);
CREATE INDEX idx_astrologer_profiles_verification_status ON astrologer_profiles(verification_status);
CREATE INDEX idx_astrologer_profiles_availability_status ON astrologer_profiles(availability_status);
CREATE INDEX idx_astrologer_profiles_average_rating ON astrologer_profiles(average_rating);
CREATE INDEX idx_astrologer_profiles_kyc_status ON astrologer_profiles(kyc_status);
CREATE INDEX idx_astrologer_profiles_kyc_request_id ON astrologer_profiles(kyc_request_id);

CREATE INDEX idx_consultations_user_id ON consultations(user_id);
CREATE INDEX idx_consultations_astrologer_id ON consultations(astrologer_id);
CREATE INDEX idx_consultations_status ON consultations(status);
CREATE INDEX idx_consultations_scheduled_at ON consultations(scheduled_at);
CREATE INDEX idx_consultations_booking_id ON consultations(booking_id);

CREATE INDEX idx_payments_consultation_id ON payments(consultation_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_gateway_transaction_id ON payments(gateway_transaction_id);

CREATE INDEX idx_reviews_astrologer_id ON reviews(astrologer_id);
CREATE INDEX idx_reviews_rating ON reviews(rating);
CREATE INDEX idx_reviews_consultation_id ON reviews(consultation_id);

CREATE INDEX idx_chat_messages_consultation_id ON chat_messages(consultation_id);
CREATE INDEX idx_chat_messages_sender_id ON chat_messages(sender_id);

CREATE INDEX idx_wallet_transactions_wallet_id ON wallet_transactions(wallet_id);
CREATE INDEX idx_wallet_transactions_created_at ON wallet_transactions(created_at);

CREATE INDEX idx_kyc_audit_logs_astrologer_profile_id ON kyc_audit_logs(astrologer_profile_id);
CREATE INDEX idx_kyc_audit_logs_kyc_request_id ON kyc_audit_logs(kyc_request_id);
CREATE INDEX idx_kyc_audit_logs_event_type ON kyc_audit_logs(event_type);
CREATE INDEX idx_kyc_audit_logs_created_at ON kyc_audit_logs(created_at);

-- Create functions for updating timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for automatic timestamp updates
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_astrologer_profiles_updated_at BEFORE UPDATE ON astrologer_profiles
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_consultations_updated_at BEFORE UPDATE ON consultations
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_user_wallets_updated_at BEFORE UPDATE ON user_wallets
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- Function to generate booking ID
CREATE OR REPLACE FUNCTION generate_booking_id()
RETURNS TEXT AS $$
DECLARE
    new_id TEXT;
    exists BOOLEAN;
BEGIN
    LOOP
        new_id := 'AT' || LPAD((RANDOM() * 99999999)::INTEGER::TEXT, 8, '0');
        SELECT EXISTS(SELECT 1 FROM consultations WHERE booking_id = new_id) INTO exists;
        IF NOT exists THEN
            EXIT;
        END IF;
    END LOOP;
    RETURN new_id;
END;
$$ LANGUAGE plpgsql;

-- Function to update astrologer rating
CREATE OR REPLACE FUNCTION update_astrologer_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE astrologer_profiles 
    SET 
        average_rating = (
            SELECT ROUND(AVG(rating)::NUMERIC, 2) 
            FROM reviews 
            WHERE astrologer_id = NEW.astrologer_id
        ),
        total_ratings = (
            SELECT COUNT(*) 
            FROM reviews 
            WHERE astrologer_id = NEW.astrologer_id
        ),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.astrologer_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update astrologer rating when a review is added
CREATE TRIGGER update_astrologer_rating_trigger 
    AFTER INSERT ON reviews
    FOR EACH ROW 
    EXECUTE PROCEDURE update_astrologer_rating();

-- Sample data for testing (optional)
-- Insert admin user
INSERT INTO users (
    cognito_user_id, phone_number, email, user_type, profile_status,
    first_name, last_name, city, country, is_phone_verified, is_email_verified
) VALUES (
    'admin-cognito-id', '+919999999999', 'admin@astrotalk.com', 'admin', 'approved',
    'Admin', 'User', 'Mumbai', 'India', true, true
);

-- Insert sample promo codes
INSERT INTO promo_codes (code, description, discount_type, discount_value, max_discount_amount, min_order_amount, usage_limit, valid_until)
VALUES 
('WELCOME50', 'Welcome bonus for new users', 'percentage', 50.00, 200.00, 100.00, 1000, '2025-12-31 23:59:59+05:30'),
('FIRST100', 'First consultation discount', 'fixed', 100.00, null, 200.00, 500, '2025-12-31 23:59:59+05:30');
