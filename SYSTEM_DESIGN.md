# AstroTalk System Design - Authentication & Consultation Booking

## Overview
This document outlines the system design for an AstroTalk.com replica focusing on user/astrologer authentication and consultation booking functionality.

## Architecture Components

### 1. Authentication Service (AWS Cognito)
- **User Pool**: Manages user identities for both regular users and astrologers
- **Identity Pool**: Provides temporary AWS credentials for authenticated users
- **Custom Attributes**: Extended fields for astrologer profiles
- **Multi-Factor Authentication**: SMS-based OTP for mobile verification

### 2. Application Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Mobile App    │    │    Web App      │    │   Admin Panel   │
│   (React Native)│    │   (React/Next)  │    │   (React/Next)  │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────▼─────────────┐
                    │      API Gateway         │
                    │    (AWS API Gateway)     │
                    └─────────────┬─────────────┘
                                 │
                    ┌─────────────▼─────────────┐
                    │   Authentication API     │
                    │     (Lambda Functions)   │
                    └─────────────┬─────────────┘
                                 │
        ┌────────────────────────┼────────────────────────┬─────────────────┐
        │                       │                        │                 │
┌───────▼───────┐    ┌─────────▼─────────┐    ┌─────────▼─────────┐  ┌─────▼─────┐
│ AWS Cognito   │    │  PostgreSQL DB   │    │   File Storage    │  │  Digio    │
│  User Pool    │    │   (RDS/Aurora)    │    │      (S3)         │  │ KYC API   │
└───────────────┘    └───────────────────┘    └───────────────────┘  └───────────┘
```

## 3. Authentication Flows

### User Registration Flow
```
User Input → Mobile Verification → Cognito Registration → Profile Creation → Success
```

### Astrologer Registration Flow
```
Astrologer Input → Mobile Verification → Document Upload → KYC Verification (Digio) → Auto-Approval → Profile Activation → Success
                                                                     ↓
                                                        (Optional: Admin Review for Quality Check)
```

### Login Flow (Both User Types)
```
Mobile Number → Send OTP → Verify OTP → Cognito Returns JWT Tokens → Session Established → Access Granted
                                          ↓
                                   (Access Token, ID Token, Refresh Token)
```

## 4. AWS Cognito Configuration

### User Pool Settings
- **Sign-in options**: Phone number
- **MFA**: SMS text message
- **Password policy**: Not required (OTP-based auth)
- **Custom attributes**:
  - user_type (user/astrologer)
  - profile_status (pending/approved/rejected)
  - kyc_status (not_started/in_progress/completed/failed/rejected)
  - city
  - specializations (for astrologers)

### Identity Pool Settings
- **Authentication providers**: Cognito User Pool
- **Unauthenticated access**: Disabled
- **Role mapping**: Based on user_type attribute

### JWT Token Management
AWS Cognito automatically generates three types of JWT tokens upon successful authentication:

1. **Access Token**:
   - **Purpose**: API authorization and access control
   - **Contains**: User permissions, groups, custom attributes
   - **Lifetime**: 1 hour (configurable)
   - **Usage**: Sent with API requests in Authorization header

2. **ID Token**:
   - **Purpose**: User identity information
   - **Contains**: User profile data (name, email, phone, custom attributes)
   - **Lifetime**: 1 hour (configurable)
   - **Usage**: Client-side user information display

3. **Refresh Token**:
   - **Purpose**: Obtain new Access and ID tokens without re-authentication
   - **Contains**: Encrypted refresh credentials
   - **Lifetime**: 30 days (configurable)
   - **Usage**: Automatic token refresh for seamless user experience

### Session Management Strategy
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Mobile App    │    │   API Gateway    │    │   Lambda/API    │
│                 │    │                  │    │                 │
│ Access Token    │───▶│ Token Validation │───▶│ Authorized      │
│ (1 hour TTL)    │    │ + Rate Limiting  │    │ Request         │
│                 │    │                  │    │                 │
│ Auto-refresh    │◀───│ 401 Unauthorized │◀───│ Token Expired   │
│ using Refresh   │    │                  │    │                 │
│ Token if needed │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 5. Security Considerations

- **JWT Token Management**: Short-lived access tokens (1 hour) with refresh tokens (30 days)
- **Rate Limiting**: OTP requests limited to 3 per 15 minutes, KYC requests limited to 3 per user
- **Data Encryption**: All sensitive data encrypted at rest and in transit
- **Role-Based Access Control**: Different permissions for users, astrologers, and admins
- **KYC Security**: 
  - Webhook signature verification from Digio
  - Secure handling of PII data during KYC process
  - Audit logging of all KYC events
  - IP address tracking for KYC sessions
- **Input Validation**: All inputs sanitized and validated
- **CORS Configuration**: Restricted to allowed origins

## 6. Scalability Features

- **Auto Scaling**: Lambda functions scale automatically
- **Database Scaling**: Aurora Serverless for automatic scaling
- **CDN**: CloudFront for static assets and profile pictures
- **Caching**: ElastiCache for session management and frequently accessed data
- **Load Balancing**: ALB for distributing traffic across multiple AZs

## 7. Monitoring & Analytics

- **AWS CloudWatch**: For application logs and metrics
- **AWS X-Ray**: For distributed tracing
- **Custom Metrics**: 
  - User engagement and booking conversion rates
  - KYC completion rates and failure reasons
  - Astrologer onboarding funnel metrics
- **Security Monitoring**: 
  - Failed login attempts and suspicious activities
  - KYC fraud detection and unusual patterns
  - Webhook security violations

## 8. Digio KYC Integration

### 8.1 Integration Architecture
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Astrologer    │    │  AstroTalk API   │    │   Digio KYC     │
│   Mobile App    │    │   (Lambda)       │    │   Gateway       │
└─────────┬───────┘    └─────────┬────────┘    └─────────┬───────┘
          │                      │                       │
          │ 1. Initiate KYC      │                       │
          │─────────────────────▶│ 2. Create KYC Request │
          │                      │──────────────────────▶│
          │                      │ 3. Return Gateway URL │
          │                      │◀──────────────────────│
          │ 4. Gateway URL       │                       │
          │◀─────────────────────│                       │
          │                      │                       │
          │ 5. Redirect to Digio Gateway                │
          │────────────────────────────────────────────▶│
          │                      │                       │
          │ 6. Complete KYC Process                     │
          │◀────────────────────────────────────────────│
          │                      │                       │
          │                      │ 7. Webhook Notification
          │                      │◀──────────────────────│
          │ 8. Push Notification │                       │
          │◀─────────────────────│                       │
```

### 8.2 KYC Configuration
- **Environment**: Sandbox (testing) and Production
- **Document Types**: PAN Card, Aadhaar Card
- **Verification Type**: Video KYC with live agent
- **Session Duration**: 30 minutes maximum
- **Retry Policy**: Maximum 3 attempts per astrologer
- **Data Retention**: KYC data retained as per compliance requirements

### 8.3 Webhook Security
- **Signature Verification**: HMAC-SHA256 signature validation
- **Idempotency**: Duplicate webhook handling
- **Timeout Handling**: Webhook retry mechanism with exponential backoff
- **Error Handling**: Comprehensive error logging and alerting

### 8.4 Compliance & Privacy
- **Data Minimization**: Only necessary data shared with Digio
- **Consent Management**: Clear user consent for KYC process
- **Data Retention**: Automated cleanup of expired KYC sessions
- **Audit Trail**: Complete audit log of all KYC interactions

## 9. Backup & Disaster Recovery

- **Database Backups**: Daily automated backups with point-in-time recovery
- **Cross-Region Replication**: For critical data
- **KYC Data Protection**: Encrypted backups of KYC audit logs
- **Infrastructure as Code**: CloudFormation/Terraform for reproducible deployments
