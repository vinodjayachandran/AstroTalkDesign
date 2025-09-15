# AstroTalk System Design Documentation

This repository contains the complete system design documentation for an AstroTalk.com replica, focusing on user and astrologer authentication with consultation booking functionality.

## 📋 Project Overview

AstroTalk is an astrology consultation platform that connects users with verified astrologers. The system supports multiple consultation types (video, call, chat) with secure mobile OTP-based authentication using AWS Cognito.

## 🏗️ Architecture Components

- **Authentication**: AWS Cognito with mobile OTP verification
- **Database**: PostgreSQL with comprehensive schema design
- **API**: RESTful APIs with JWT token authentication
- **File Storage**: AWS S3 for profile pictures and documents
- **Payment**: Multi-gateway support (Razorpay, Stripe)
- **Real-time**: WebSocket support for live consultations

## 📁 Documentation Structure

### 1. [System Design](./SYSTEM_DESIGN.md)
Comprehensive architecture overview including:
- AWS Cognito configuration
- Application architecture diagrams
- Security considerations
- Scalability features
- Monitoring and backup strategies

### 2. [Database Schema](./database_schema.sql)
Complete PostgreSQL database schema with:
- User and astrologer management tables
- Consultation booking system
- Payment and wallet functionality
- Reviews and ratings system
- Promotional codes and discounts
- Triggers and functions for data consistency

### 3. [Authentication Flow](./authentication_flow.md)
Detailed mobile OTP authentication implementation with **Mermaid sequence diagrams**:
- User and astrologer registration flows
- Login process with SMS OTP
- Token refresh mechanisms
- AWS Cognito integration code
- Security measures and rate limiting

### 4. [API Endpoints](./api_endpoints.md)
Complete REST API specification including:
- Authentication endpoints
- User profile management
- Astrologer discovery and booking
- Consultation management
- Wallet and payment operations
- Review and rating system

### 5. [Data Models](./data_models_relationships.md)
Comprehensive data modeling documentation with **Mermaid ER diagrams**:
- Entity relationship diagrams
- TypeScript interface definitions
- Business logic and relationships
- Data constraints and validations
- Indexing and scalability strategies

### 6. [Database Diagram (Simple)](./database_diagram_simple.md)
Simplified database schema visualization with **Mermaid flowcharts**:
- High-level table relationships
- Grouped by functional areas
- Color-coded components
- Easy-to-understand overview

## 🚀 Key Features

### User Management
- **Dual User Types**: Regular users and astrologers
- **Mobile OTP Authentication**: Secure phone-based verification
- **Profile Management**: Comprehensive user profiles with additional astrologer fields
- **Document Verification**: Admin-managed astrologer verification process

### Consultation System
- **Multiple Types**: Video, voice call, chat, and email consultations
- **Real-time Booking**: Availability checking and instant booking
- **Flexible Pricing**: Per-minute pricing with promotional discounts
- **Session Management**: Secure session URLs and chat rooms

### Payment & Wallet
- **Digital Wallet**: In-app wallet for seamless payments
- **Multiple Gateways**: Support for various payment methods
- **Automatic Refunds**: Smart refund processing for cancellations
- **Transaction History**: Comprehensive payment tracking

### Rating & Reviews
- **Verified Reviews**: Only post-consultation reviews allowed
- **Rating Aggregation**: Automatic rating calculations
- **Public Display**: Transparent astrologer ratings

## 🔒 Security Features

- **JWT Token Management**: Short-lived access tokens with refresh capability
- **Rate Limiting**: API endpoint protection against abuse
- **Data Encryption**: All sensitive data encrypted at rest and in transit
- **Role-Based Access**: Different permissions for users, astrologers, and admins
- **Input Validation**: Comprehensive sanitization and validation

## ⚡ Performance & Scalability

- **Auto Scaling**: Lambda functions and Aurora Serverless
- **Caching Strategy**: Redis for sessions and frequently accessed data
- **CDN Integration**: CloudFront for static asset delivery
- **Database Optimization**: Strategic indexing and query optimization
- **Monitoring**: CloudWatch and X-Ray for comprehensive observability

## 🛠️ Technology Stack

- **Backend**: Node.js with AWS Lambda
- **Database**: PostgreSQL (AWS RDS/Aurora)
- **Authentication**: AWS Cognito
- **File Storage**: AWS S3
- **API Gateway**: AWS API Gateway
- **Caching**: Redis (ElastiCache)
- **Monitoring**: CloudWatch, X-Ray
- **Payment**: Razorpay, Stripe

## 📊 Database Design Highlights

### Core Tables
- `users` - User authentication and basic profile
- `astrologer_profiles` - Extended astrologer information
- `consultations` - Booking and session management
- `payments` - Transaction processing
- `reviews` - Rating and feedback system
- `user_wallets` - Digital wallet management

### Key Relationships
- One-to-One: User ↔ AstrologerProfile
- One-to-Many: User ↔ Consultations
- One-to-Many: AstrologerProfile ↔ Consultations
- One-to-One: Consultation ↔ Payment
- One-to-Many: Consultation ↔ ChatMessages

## 🔧 Implementation Notes

### AWS Cognito Configuration
- Phone number as primary identifier
- Custom attributes for user types and metadata
- SMS MFA for OTP verification
- JWT token management with refresh capability

### Database Features
- UUID primary keys for security
- Comprehensive indexes for performance
- Triggers for automatic calculations
- Check constraints for data integrity
- JSONB for flexible document storage

### API Design Principles
- RESTful resource-based URLs
- Consistent error response format
- Comprehensive input validation
- Rate limiting and security headers
- Pagination for list endpoints

## 📈 Business Logic

### Registration Flow
1. Phone number validation
2. AWS Cognito user creation
3. SMS OTP verification
4. Database profile creation
5. Astrologer document verification (if applicable)

### Booking Flow
1. Astrologer availability check
2. Price calculation with discounts
3. Payment processing (wallet + gateway)
4. Consultation scheduling
5. Confirmation notifications

### Payment Processing
1. Wallet balance check
2. Gateway integration for additional amount
3. Transaction logging
4. Automatic refund handling
5. Financial reconciliation

---

*Last Updated: September 15, 2025*
