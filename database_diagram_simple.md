# AstroTalk Database Schema - Simple Diagram

## Database Schema Overview (No Graphviz Required)

```mermaid
graph TD
    subgraph "Core User Management"
        A[USERS]
        B[ASTROLOGER_PROFILES]
        C[USER_WALLETS]
    end
    
    subgraph "Consultation & Booking"
        D[CONSULTATIONS]
        E[PAYMENTS]
        F[REVIEWS]
    end
    
    subgraph "Supporting Tables"
        G[WALLET_TRANSACTIONS]
        H[PROMO_CODES]
        I[CHAT_MESSAGES]
        J[ASTROLOGER_AVAILABILITY]
    end

    A -->|1:1| B
    A -->|1:1| C
    A -->|1:M| D
    A -->|1:M| F
    A -->|1:M| I

    B -->|1:M| D
    B -->|1:M| F
    B -->|1:M| J

    D -->|1:1| E
    D -->|1:1| F
    D -->|1:M| I

    C -->|1:M| G
    H -->|M:M| D

    classDef userMgmt fill:#e1f5fe
    classDef consultation fill:#f3e5f5
    classDef support fill:#e8f5e8

    class A,B,C userMgmt
    class D,E,F consultation
    class G,H,I,J support
```

## Table Descriptions

### Core Tables

**USERS**
- Primary user authentication and profile
- AWS Cognito integration
- Phone number as primary identifier

**ASTROLOGER_PROFILES**
- Extended profile for astrologers
- Verification and rating system
- Specializations and availability

**CONSULTATIONS**
- Central booking table
- Links users with astrologers
- Multiple consultation types

**PAYMENTS**
- Payment processing
- Multiple gateway support
- Refund handling

### Key Relationships

1. **User → Astrologer**: One-to-one (optional)
2. **User → Consultations**: One-to-many
3. **Astrologer → Consultations**: One-to-many
4. **Consultation → Payment**: One-to-one
5. **User → Wallet**: One-to-one
6. **Wallet → Transactions**: One-to-many

This simplified diagram shows the core structure without requiring complex rendering engines.
