# Test Coverage Audit Report

**Date:** 2025-01-27  
**Coverage:** 10.42%  
**Status:** Critical gaps identified

---

## Executive Summary

The application currently has **very low test coverage** at 10.42%. While good quality tests exist for core business logic (Membership, Payment processing), most models, controllers, and services lack test coverage.

**Critical Priority:** Focus on controller tests for admin area and core business models before expanding feature development.

---

## Coverage Breakdown

### Models (24 total, 12 tested = 50%)

#### ✅ **Well Tested Models**
- `User` - User spec exists
- `Person` - Person spec exists
- `Membership` - Membership spec exists
- `Payment` - Payment spec exists
- `PaymentLine` - PaymentLine spec exists
- `MembershipType` - MembershipType spec exists
- `BookOfEntry` - Comprehensive tests including business logic
- `Event` - Basic tests exist

#### ⚠️ **Partially Tested Models**
- Complex logic tested in integration tests but no dedicated specs

#### ❌ **Untested Models (HIGH PRIORITY)**
- `SubscriptionPlan` - Critical for pricing logic, pack10 subscriptions
- `AccountClaim` - Workflow for account claiming/recovery
- `Attendance` - Event registration, daily attendance
- `AttendanceList` - Attendance management
- `Blog` - CMS functionality
- `Tag` / `TagBlog` - Content management
- `PriceCatalog` / `PriceEntry` - Pricing structure
- `PaymentAuditLog` - Audit trail critical for compliance
- `MemberNumberHistory` - History tracking
- `EventAttendee` - Event management
- `Session` - Session management
- `UserService` - User business logic

**Estimation:** 12 specs needed for models

---

### Controllers (34 total, 0 tested = 0%)

#### 🔴 **CRITICAL: Admin Controllers (18 total)**

**Account/User Management:**
- `Admin::UsersController` - User CRUD operations
- `Admin::Users::PaymentsController` - User payment management
- `Admin::MemberNumbersController` - Member number management

**Membership Management:**
- `Admin::MembershipsController` - Membership CRUD
- `Admin::MembershipTypesController` - Membership type management

**Financial Operations:**
- `Admin::PaymentsController` - Payment processing and management
- `Admin::DonationsController` - Donation handling

**Events & Attendance:**
- `Admin::EventsController` - Event CRUD and management
- `Admin::AttendancesController` - Attendance tracking
- `Admin::AttendanceListsController` - Attendance list management

**Content Management:**
- `Admin::BlogsController` - Blog/CMS management
- `Admin::PriceCatalogController` - Price management

**Subscription Management:**
- `Admin::SubscriptionPlansController` - Subscription plan CRUD

**Utilities:**
- `Admin::DashboardController` - Dashboard stats
- `Admin::ExportsController` - Data exports
- `Admin::OpeningHoursController` - Opening hours management
- `Admin::NotepadsController` - Admin notes
- `Admin::SessionsController` - Admin authentication

**Estimation:** 18 request specs needed for admin controllers

#### ⚠️ **Public Controllers (16 total)**

**Authentication & Account:**
- `SessionsController` - User login/logout
- `RegistrationsController` - User signup
- `AccountClaimsController` - Account claiming
- `PasswordsController` - Password reset

**Public Pages:**
- `HomeController` - Homepage
- `EventsController` - Public event listings
- `BlogsController` - Public blog
- `PagesController` - Static pages
- `ContactsController` - Contact form

**User Area:**
- `UsersController` - User profile
- `SettingsController` - User settings
- `CheckoutController` - Payment checkout

**Estimation:** 11 request specs needed for public controllers

---

### Services (21 total, 3 tested = 14%)

#### ✅ **Tested Services**
- `MemberManagementService` - Comprehensive tests
- `Payments::Process` - Comprehensive tests with integration
- `Memberships::Upgrade` - Comprehensive tests with business logic validation

#### ❌ **Untested Services (HIGH PRIORITY)**

**User Management:**
- `UserService` - User business logic
- `UserManagement::UserCreator` - User creation logic
- `UserManagement::UserDeleter` - User deletion logic
- `UserManagement::AccountCreator` - Account setup
- `Web::UserRegistration` - Registration workflow

**Person Management:**
- `PersonManagement::PersonCreator` - Person creation
- `PersonManagement::PersonMerger` - Person merge logic

**Payment Management:**
- `PaymentManagement::PaymentCreator` - Payment creation
- `PaymentManagement::PaymentUpdater` - Payment updates
- `PaymentManagement::PaymentDeleter` - Payment deletion
- `PaymentManagement::PaymentRestorer` - Payment restoration
- `PaymentManagement::RefundCreator` - Refund processing

**Membership Management:**
- `MembershipManagement::MembershipCreator` - Membership creation
- `MembershipManagement::MembershipUpgrader` - Upgrade logic (complement to Memberships::Upgrade)

**Event Management:**
- `EventManagement::EventCreator` - Event creation
- `EventManagement::EventUpdater` - Event updates
- `EventManagement::EventDeleter` - Event deletion

**Utilities:**
- `NewsletterSignupService` - Newsletter signup
- `Admin::PaymentsService` - Admin payment logic

**Estimation:** 18 service specs needed

---

### Helpers (minimal testing)
- `Admin::Users::DisplayHelper` - Basic display helper tests exist
- Other helpers need testing

---

## Priority Testing Roadmap

### Phase 1: Critical Business Logic (Week 1)
**Goal:** Ensure core business operations are safe to deploy

1. **Models:**
   - [ ] `SubscriptionPlan` spec - Pricing and pack logic
   - [ ] `AccountClaim` spec - Account workflow
   - [ ] `Attendance` spec - Event/daily attendance logic

2. **Services:**
   - [ ] `UserManagement::UserCreator` spec
   - [ ] `PaymentManagement::PaymentCreator` spec
   - [ ] `MembershipManagement::MembershipCreator` spec
   - [ ] `EventManagement::EventCreator` spec

3. **Controllers (Request specs):**
   - [ ] `Admin::UsersController` requests
   - [ ] `Admin::PaymentsController` requests
   - [ ] `Admin::EventsController` requests

**Total:** ~9 specs

---

### Phase 2: Complete Admin Area (Week 2)
**Goal:** Admin operations fully tested before staging deployment

1. **Admin Controllers:**
   - [ ] All remaining admin controllers (15 specs)
   - [ ] Authentication flow (`Admin::SessionsController`)

2. **Core Services:**
   - [ ] All payment management services (4 specs)
   - [ ] All membership management services (1 spec)
   - [ ] All event management services (2 specs)

**Total:** ~22 specs

---

### Phase 3: Public & User Area (Week 3)
**Goal:** User-facing features tested

1. **Public Controllers:**
   - [ ] Authentication controllers (3 specs)
   - [ ] User profile/settings (3 specs)
   - [ ] Checkout flow (1 spec)
   - [ ] Public pages (4 specs)

2. **Remaining Models:**
   - [ ] CMS models (Blog, Tag) (2 specs)
   - [ ] Pricing models (PriceCatalog, PriceEntry) (2 specs)
   - [ ] Audit/history models (3 specs)

**Total:** ~18 specs

---

### Phase 4: Edge Cases & Integration (Ongoing)
**Goal:** Comprehensive coverage and confidence

1. **Integration Tests:**
   - [ ] Complete user registration → membership → payment flow
   - [ ] Event registration → attendance tracking
   - [ ] Admin workflows end-to-end

2. **Edge Cases:**
   - [ ] Error handling in all services
   - [ ] Concurrency issues
   - [ ] Data migration scenarios

---

## Estimated Total Work

- **Models specs:** ~12 specs
- **Controller specs:** ~29 specs
- **Service specs:** ~18 specs
- **Integration specs:** ~6 specs

**Grand Total:** ~65 specs to achieve >80% coverage

---

## Recommendations

### Immediate Actions
1. ✅ SimpleCov activated with 60% minimum threshold
2. ⏳ Lower threshold temporarily to 40% while catching up
3. ⏳ Add CI blocking for coverage drops

### TDD Workflow
1. Before adding ANY new feature, write failing specs first
2. Use request specs for controller testing (not controller specs)
3. Use service specs for all business logic
4. Keep model specs focused on validations and associations

### CI/CD Strategy
1. All specs must pass before merge to `dev`
2. Coverage must not decrease
3. Staging deploy only if tests pass
4. Add smoke tests after staging deploy

---

## Current Coverage

```
Total Coverage: 10.42%

By Type:
- Models: ~50% (12/24 models)
- Controllers: 0% (0/34 controllers)
- Services: ~14% (3/21 services)
- Helpers: ~5% (1/? helpers)
```

---

## Notes

- FactoryBot is properly configured
- Shoulda-matchers is now configured
- RSpec JUnit formatter configured for CI
- Tests run in transactions (good for speed)
- Integration tests are manually managed

**Next Audit:** After Phase 1 completion

