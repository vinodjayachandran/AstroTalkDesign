# AstroTalk API Endpoints Specification

## Base URL
```
Production: https://api.astrotalk.com/v1
Staging: https://api-staging.astrotalk.com/v1
```

## Authentication Headers
```
Authorization: Bearer <access_token>
Content-Type: application/json
X-App-Version: 1.0.0
X-Platform: ios|android|web
```

## 1. Authentication Endpoints

### 1.1 User Registration
```http
POST /auth/register
```

**Request Body:**
```json
{
  "phone_number": "+919876543210",
  "user_type": "user|astrologer",
  "first_name": "John",
  "last_name": "Doe",
  "email": "john.doe@example.com",
  "city": "Mumbai",
  "date_of_birth": "1990-01-15",
  "gender": "male",
  // Astrologer specific fields
  "bio": "Experienced Vedic astrologer...",
  "experience_years": 5,
  "languages": ["Hindi", "English"],
  "specializations": ["Vedic Astrology", "Tarot"],
  "education": "MA in Astrology",
  "consultation_rate_per_minute": 25.00
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "OTP sent successfully",
  "data": {
    "session_id": "eyJhbGciOiJSUzI1NiJ9...",
    "challenge_name": "SMS_MFA",
    "phone_number": "+919876543210",
    "otp_expires_at": "2025-09-15T10:05:00Z"
  }
}
```

### 1.2 Verify Registration OTP
```http
POST /auth/verify-registration
```

**Request Body:**
```json
{
  "session_id": "eyJhbGciOiJSUzI1NiJ9...",
  "otp_code": "123456",
  "profile_picture": "base64_encoded_image" // Optional
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Registration successful",
  "data": {
    "access_token": "eyJhbGciOiJSUzI1NiJ9...",
    "refresh_token": "eyJhbGciOiJSUzI1NiJ9...",
    "id_token": "eyJhbGciOiJSUzI1NiJ9...",
    "expires_in": 3600,
    "user": {
      "id": "uuid",
      "phone_number": "+919876543210",
      "email": "john.doe@example.com",
      "user_type": "user",
      "profile_status": "approved",
      "first_name": "John",
      "last_name": "Doe",
      "profile_picture_url": "https://s3.amazonaws.com/...",
      "created_at": "2025-09-15T10:00:00Z"
    }
  }
}
```

### 1.3 Login (Send OTP)
```http
POST /auth/login
```

**Request Body:**
```json
{
  "phone_number": "+919876543210"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "OTP sent successfully",
  "data": {
    "session_id": "eyJhbGciOiJSUzI1NiJ9...",
    "challenge_name": "SMS_MFA",
    "phone_number": "+919876543210",
    "otp_expires_at": "2025-09-15T10:05:00Z"
  }
}
```

### 1.4 Verify Login OTP
```http
POST /auth/verify-login
```

**Request Body:**
```json
{
  "session_id": "eyJhbGciOiJSUzI1NiJ9...",
  "otp_code": "123456"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "access_token": "eyJhbGciOiJSUzI1NiJ9...",
    "refresh_token": "eyJhbGciOiJSUzI1NiJ9...",
    "id_token": "eyJhbGciOiJSUzI1NiJ9...",
    "expires_in": 3600,
    "user": {
      "id": "uuid",
      "phone_number": "+919876543210",
      "user_type": "astrologer",
      "profile_status": "approved",
      "first_name": "John",
      "last_name": "Doe",
      "profile_picture_url": "https://s3.amazonaws.com/...",
      "last_login": "2025-09-15T10:00:00Z"
    }
  }
}
```

### 1.5 Refresh Token
```http
POST /auth/refresh
```

**Request Body:**
```json
{
  "refresh_token": "eyJhbGciOiJSUzI1NiJ9..."
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJSUzI1NiJ9...",
    "id_token": "eyJhbGciOiJSUzI1NiJ9...",
    "expires_in": 3600
  }
}
```

### 1.6 Logout
```http
POST /auth/logout
```

**Headers:** `Authorization: Bearer <access_token>`

**Response (200):**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

## 2. User Profile Endpoints

### 2.1 Get User Profile
```http
GET /users/profile
```

**Headers:** `Authorization: Bearer <access_token>`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "phone_number": "+919876543210",
    "email": "john.doe@example.com",
    "user_type": "user",
    "profile_status": "approved",
    "first_name": "John",
    "last_name": "Doe",
    "date_of_birth": "1990-01-15",
    "gender": "male",
    "city": "Mumbai",
    "state": "Maharashtra",
    "country": "India",
    "profile_picture_url": "https://s3.amazonaws.com/...",
    "is_phone_verified": true,
    "is_email_verified": false,
    "created_at": "2025-09-15T10:00:00Z",
    "wallet_balance": 500.00
  }
}
```

### 2.2 Update User Profile
```http
PUT /users/profile
```

**Headers:** `Authorization: Bearer <access_token>`

**Request Body:**
```json
{
  "first_name": "John",
  "last_name": "Smith",
  "email": "john.smith@example.com",
  "date_of_birth": "1990-01-15",
  "gender": "male",
  "city": "Delhi",
  "state": "Delhi"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    // Updated user object
  }
}
```

### 2.3 Upload Profile Picture
```http
POST /users/profile/picture
```

**Headers:** `Authorization: Bearer <access_token>`

**Request Body (multipart/form-data):**
```
file: <image_file>
```

**Response (200):**
```json
{
  "success": true,
  "message": "Profile picture updated successfully",
  "data": {
    "profile_picture_url": "https://s3.amazonaws.com/..."
  }
}
```

## 3. Astrologer Endpoints

### 3.1 Get Astrologer Profile
```http
GET /astrologers/{astrologer_id}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "user_id": "uuid",
    "display_name": "Pandit John Doe",
    "bio": "Experienced Vedic astrologer with 10+ years...",
    "experience_years": 10,
    "languages": ["Hindi", "English", "Marathi"],
    "specializations": ["Vedic Astrology", "Tarot", "Numerology"],
    "education": "MA in Astrology, PhD in Sanskrit",
    "certifications": ["Certified Vedic Astrologer"],
    "consultation_rate_per_minute": 35.00,
    "availability_status": true,
    "total_consultations": 1250,
    "average_rating": 4.7,
    "total_ratings": 890,
    "profile_picture_url": "https://s3.amazonaws.com/...",
    "verification_status": "approved",
    "created_at": "2025-01-15T10:00:00Z"
  }
}
```

### 3.2 Get Astrologers List
```http
GET /astrologers
```

**Query Parameters:**
```
page=1
limit=20
sort_by=rating|experience|price|popularity
sort_order=asc|desc
languages[]=Hindi&languages[]=English
specializations[]=Vedic&specializations[]=Tarot
min_rating=4.0
max_rate=50.00
availability=true
city=Mumbai
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "astrologers": [
      {
        "id": "uuid",
        "display_name": "Pandit John Doe",
        "experience_years": 10,
        "languages": ["Hindi", "English"],
        "specializations": ["Vedic Astrology"],
        "consultation_rate_per_minute": 35.00,
        "availability_status": true,
        "average_rating": 4.7,
        "total_ratings": 890,
        "profile_picture_url": "https://s3.amazonaws.com/..."
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 25,
      "total_items": 500,
      "items_per_page": 20
    }
  }
}
```

### 3.3 Update Astrologer Profile
```http
PUT /astrologers/profile
```

**Headers:** `Authorization: Bearer <access_token>`

**Request Body:**
```json
{
  "display_name": "Pandit John Doe",
  "bio": "Experienced Vedic astrologer...",
  "languages": ["Hindi", "English", "Marathi"],
  "specializations": ["Vedic Astrology", "Tarot"],
  "education": "MA in Astrology",
  "consultation_rate_per_minute": 40.00,
  "availability_status": true
}
```

## 4. Consultation Booking Endpoints

### 4.1 Check Astrologer Availability
```http
GET /astrologers/{astrologer_id}/availability
```

**Query Parameters:**
```
date=2025-09-15
timezone=Asia/Kolkata
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "date": "2025-09-15",
    "timezone": "Asia/Kolkata",
    "available_slots": [
      {
        "start_time": "09:00",
        "end_time": "09:30",
        "is_available": true
      },
      {
        "start_time": "09:30",
        "end_time": "10:00",
        "is_available": false
      }
    ]
  }
}
```

### 4.2 Book Consultation
```http
POST /consultations
```

**Headers:** `Authorization: Bearer <access_token>`

**Request Body:**
```json
{
  "astrologer_id": "uuid",
  "consultation_type": "video|call|chat",
  "scheduled_at": "2025-09-15T09:00:00+05:30",
  "duration_minutes": 30,
  "user_question": "I want to know about my career prospects",
  "promo_code": "WELCOME50",
  "payment_method": "wallet|razorpay"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Consultation booked successfully",
  "data": {
    "consultation": {
      "id": "uuid",
      "booking_id": "AT12345678",
      "astrologer": {
        "id": "uuid",
        "display_name": "Pandit John Doe",
        "profile_picture_url": "https://s3.amazonaws.com/..."
      },
      "consultation_type": "video",
      "status": "scheduled",
      "scheduled_at": "2025-09-15T09:00:00+05:30",
      "duration_minutes": 30,
      "rate_per_minute": 35.00,
      "total_amount": 1050.00,
      "discount_amount": 525.00,
      "final_amount": 525.00,
      "payment_status": "completed"
    },
    "payment": {
      "id": "uuid",
      "amount": 525.00,
      "currency": "INR",
      "status": "completed",
      "payment_method": "wallet"
    }
  }
}
```

### 4.3 Get User Consultations
```http
GET /consultations
```

**Headers:** `Authorization: Bearer <access_token>`

**Query Parameters:**
```
status=scheduled|completed|cancelled
page=1
limit=10
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "consultations": [
      {
        "id": "uuid",
        "booking_id": "AT12345678",
        "astrologer": {
          "id": "uuid",
          "display_name": "Pandit John Doe",
          "profile_picture_url": "https://s3.amazonaws.com/..."
        },
        "consultation_type": "video",
        "status": "scheduled",
        "scheduled_at": "2025-09-15T09:00:00+05:30",
        "duration_minutes": 30,
        "final_amount": 525.00,
        "created_at": "2025-09-14T15:30:00+05:30"
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 5,
      "total_items": 48,
      "items_per_page": 10
    }
  }
}
```

### 4.4 Get Consultation Details
```http
GET /consultations/{consultation_id}
```

**Headers:** `Authorization: Bearer <access_token>`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "booking_id": "AT12345678",
    "user": {
      "id": "uuid",
      "first_name": "John",
      "profile_picture_url": "https://s3.amazonaws.com/..."
    },
    "astrologer": {
      "id": "uuid",
      "display_name": "Pandit John Doe",
      "profile_picture_url": "https://s3.amazonaws.com/..."
    },
    "consultation_type": "video",
    "status": "completed",
    "scheduled_at": "2025-09-15T09:00:00+05:30",
    "started_at": "2025-09-15T09:02:00+05:30",
    "ended_at": "2025-09-15T09:32:00+05:30",
    "duration_minutes": 30,
    "actual_duration_minutes": 30,
    "user_question": "I want to know about my career prospects",
    "astrologer_notes": "Strong Jupiter placement indicates good career growth...",
    "session_url": "https://meeting.astrotalk.com/room/uuid",
    "final_amount": 525.00,
    "payment_status": "completed"
  }
}
```

### 4.5 Cancel Consultation
```http
POST /consultations/{consultation_id}/cancel
```

**Headers:** `Authorization: Bearer <access_token>`

**Request Body:**
```json
{
  "cancellation_reason": "Emergency came up"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Consultation cancelled successfully",
  "data": {
    "refund_amount": 525.00,
    "refund_status": "processed",
    "refund_reference": "RF12345678"
  }
}
```

## 5. Wallet & Payment Endpoints

### 5.1 Get Wallet Balance
```http
GET /wallet
```

**Headers:** `Authorization: Bearer <access_token>`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "balance": 1250.00,
    "total_credited": 2500.00,
    "total_debited": 1250.00,
    "currency": "INR"
  }
}
```

### 5.2 Add Money to Wallet
```http
POST /wallet/topup
```

**Headers:** `Authorization: Bearer <access_token>`

**Request Body:**
```json
{
  "amount": 1000.00,
  "payment_method": "razorpay|stripe|paytm"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "payment_order": {
      "id": "order_uuid",
      "amount": 1000.00,
      "currency": "INR",
      "gateway": "razorpay",
      "gateway_order_id": "order_razorpay_123",
      "status": "created"
    }
  }
}
```

### 5.3 Get Wallet Transactions
```http
GET /wallet/transactions
```

**Headers:** `Authorization: Bearer <access_token>`

**Query Parameters:**
```
type=credit|debit|refund
page=1
limit=20
from_date=2025-09-01
to_date=2025-09-15
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "transactions": [
      {
        "id": "uuid",
        "transaction_type": "debit",
        "amount": 525.00,
        "balance_after": 725.00,
        "reference_type": "consultation",
        "reference_id": "consultation_uuid",
        "description": "Payment for consultation with Pandit John Doe",
        "created_at": "2025-09-15T09:00:00+05:30"
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 3,
      "total_items": 25,
      "items_per_page": 20
    }
  }
}
```

## 6. Review & Rating Endpoints

### 6.1 Submit Review
```http
POST /consultations/{consultation_id}/review
```

**Headers:** `Authorization: Bearer <access_token>`

**Request Body:**
```json
{
  "rating": 5,
  "review_text": "Excellent consultation! Very accurate predictions.",
  "is_public": true
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Review submitted successfully",
  "data": {
    "review": {
      "id": "uuid",
      "rating": 5,
      "review_text": "Excellent consultation! Very accurate predictions.",
      "is_public": true,
      "created_at": "2025-09-15T10:30:00+05:30"
    }
  }
}
```

### 6.2 Get Astrologer Reviews
```http
GET /astrologers/{astrologer_id}/reviews
```

**Query Parameters:**
```
page=1
limit=10
sort_by=latest|rating
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "reviews": [
      {
        "id": "uuid",
        "user": {
          "first_name": "John",
          "profile_picture_url": "https://s3.amazonaws.com/..."
        },
        "rating": 5,
        "review_text": "Excellent consultation! Very accurate predictions.",
        "created_at": "2025-09-15T10:30:00+05:30"
      }
    ],
    "summary": {
      "average_rating": 4.7,
      "total_reviews": 890,
      "rating_distribution": {
        "5": 720,
        "4": 120,
        "3": 30,
        "2": 15,
        "1": 5
      }
    },
    "pagination": {
      "current_page": 1,
      "total_pages": 89,
      "total_items": 890,
      "items_per_page": 10
    }
  }
}
```

## 7. Error Response Format

All API endpoints return errors in the following format:

**Error Response (4xx/5xx):**
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": [
      {
        "field": "phone_number",
        "message": "Phone number is required"
      }
    ]
  },
  "timestamp": "2025-09-15T10:00:00Z",
  "request_id": "req_uuid"
}
```

## 8. Rate Limiting

- **Authentication endpoints**: 5 requests per minute per IP
- **General API endpoints**: 100 requests per minute per user
- **File upload endpoints**: 10 requests per minute per user

## 9. Webhook Endpoints (for payment gateways)

### 9.1 Razorpay Webhook
```http
POST /webhooks/razorpay
```

### 9.2 Stripe Webhook
```http
POST /webhooks/stripe
```

These endpoints handle payment status updates from respective payment gateways.
