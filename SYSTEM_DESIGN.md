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
        ┌────────────────────────┼────────────────────────┐
        │                       │                        │
┌───────▼───────┐    ┌─────────▼─────────┐    ┌─────────▼─────────┐
│ AWS Cognito   │    │  PostgreSQL DB   │    │   File Storage    │
│  User Pool    │    │   (RDS/Aurora)    │    │      (S3)         │
└───────────────┘    └───────────────────┘    └───────────────────┘
```

## 3. Authentication Flows

### User Registration Flow
```
User Input → Mobile Verification → Cognito Registration → Profile Creation → Success
```

### Astrologer Registration Flow
```
Astrologer Input → Mobile Verification → Document Upload → Admin Approval → Profile Creation → Success
```

### Login Flow (Both User Types)
```
Mobile Number → Send OTP → Verify OTP → Generate JWT → Access Granted
```

## 4. AWS Cognito Configuration

### User Pool Settings
- **Sign-in options**: Phone number
- **MFA**: SMS text message
- **Password policy**: Not required (OTP-based auth)
- **Custom attributes**:
  - user_type (user/astrologer)
  - profile_status (pending/approved/rejected)
  - city
  - specializations (for astrologers)

### Identity Pool Settings
- **Authentication providers**: Cognito User Pool
- **Unauthenticated access**: Disabled
- **Role mapping**: Based on user_type attribute

## 5. Security Considerations

- **JWT Token Management**: Short-lived access tokens (1 hour) with refresh tokens (30 days)
- **Rate Limiting**: OTP requests limited to 3 per 15 minutes
- **Data Encryption**: All sensitive data encrypted at rest and in transit
- **Role-Based Access Control**: Different permissions for users, astrologers, and admins
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
- **Custom Metrics**: User engagement and booking conversion rates
- **Security Monitoring**: Failed login attempts and suspicious activities

## 8. Backup & Disaster Recovery

- **Database Backups**: Daily automated backups with point-in-time recovery
- **Cross-Region Replication**: For critical data
- **Infrastructure as Code**: CloudFormation/Terraform for reproducible deployments
