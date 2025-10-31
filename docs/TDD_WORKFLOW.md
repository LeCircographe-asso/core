# TDD Workflow Guide

This document describes our Test-Driven Development (TDD) workflow for the Circographe application.

## Philosophy

We follow the **Red-Green-Refactor** cycle:

1. **Red:** Write a failing test
2. **Green:** Write the minimum code to make it pass
3. **Refactor:** Improve the code while keeping tests green

## Test Structure

### Directory Layout

```
spec/
├── models/               # Model specs (validations, associations, scopes)
├── controllers/          # Controller specs (DEPRECATED - use requests)
├── requests/             # Request specs (integration tests for controllers)
│   ├── admin/
│   └── public/
├── services/             # Service object specs
├── helpers/              # Helper specs
├── factories/            # Factory definitions
├── support/              # Shared helpers and configuration
├── rails_helper.rb       # Rails-specific RSpec configuration
└── spec_helper.rb        # Core RSpec configuration
```

### Test Naming Conventions

```ruby
# Model: spec/models/user_spec.rb
RSpec.describe User, type: :model do
  # Use describe for context/feature
  describe 'validations' do
    # Use it or specify for each test
    it { should validate_presence_of(:email) }
  end
  
  describe 'associations' do
    it { should have_many(:memberships) }
  end
  
  describe '#some_method' do
    context 'when condition' do
      it 'returns expected result' do
        # test implementation
      end
    end
  end
end

# Service: spec/services/user_management/user_creator_spec.rb
RSpec.describe UserManagement::UserCreator do
  describe '#call' do
    context 'with valid params' do
      it 'returns success result' do
        # test implementation
      end
    end
    
    context 'with invalid params' do
      it 'returns failure result' do
        # test implementation
      end
    end
  end
end

# Request: spec/requests/admin/users_spec.rb
RSpec.describe 'Admin::Users', type: :request do
  describe 'GET /admin/users' do
    context 'when authenticated' do
      it 'returns list of users' do
        # test implementation
      end
    end
  end
end
```

## Running Tests

### Quick Commands

```bash
# Run all tests with coverage
bin/test

# Run specific specs
bin/test spec/models/user_spec.rb
bin/test spec/models

# Run fast tests only (models + services)
bin/test_fast

# Run without coverage (faster)
bin/test --no-coverage

# Run tests in watch mode (requires Guard)
bin/test_watch
```

### Full Commands

```bash
# Run all tests
bundle exec rspec

# Run with documentation format
bundle exec rspec --format documentation

# Run specific file
bundle exec rspec spec/models/user_spec.rb

# Run with focus
bundle exec rspec --tag focus

# Run only failures
bundle exec rspec --only-failures

# Run with seed (to reproduce failures)
bundle exec rspec --seed 1234
```

## Test Tools

### FactoryBot

We use FactoryBot for creating test data:

```ruby
# Define factories in spec/factories/users.rb
FactoryBot.define do
  factory :user do
    email { "user@example.com" }
    password { "password123" }
    role { :admin }
    
    trait :with_person do
      person { create(:person) }
    end
  end
end

# Use in specs
let(:user) { create(:user) }
let(:admin_user) { create(:user, role: :super_admin) }
let(:user_with_person) { create(:user, :with_person) }
```

### Shoulda Matchers

We use Shoulda Matchers for concise model tests:

```ruby
RSpec.describe User, type: :model do
  # Validations
  it { should validate_presence_of(:email) }
  it { should validate_uniqueness_of(:email) }
  
  # Associations
  it { should belong_to(:person).optional }
  it { should have_many(:memberships) }
  
  # Scopes
  it { should respond_to(:active) }
  
  # Enums
  it { should define_enum_for(:role).with_values([:admin, :super_admin, :volunteer]) }
end
```

### Coverage

We use SimpleCov for coverage tracking:

```ruby
# Current threshold: 10% (low, will increase)
# After Phase 1: 40%
# After Phase 2: 60%
# Target: 80%+
```

View coverage: Open `coverage/index.html` in browser

## TDD Workflow Examples

### Example 1: Adding a Model Method

```ruby
# 1. RED: Write failing test
# spec/models/subscription_plan_spec.rb
RSpec.describe SubscriptionPlan, type: :model do
  describe '#expired?' do
    context 'when expires_at is in the past' do
      let(:plan) { build(:subscription_plan, expires_at: 1.day.ago) }
      
      it 'returns true' do
        expect(plan.expired?).to be true
      end
    end
    
    context 'when expires_at is in the future' do
      let(:plan) { build(:subscription_plan, expires_at: 1.day.from_now) }
      
      it 'returns false' do
        expect(plan.expired?).to be false
      end
    end
  end
end

# 2. GREEN: Write minimum code
# app/models/subscription_plan.rb
class SubscriptionPlan < ApplicationRecord
  def expired?
    expires_at.present? && expires_at < Time.current
  end
end

# 3. Run tests
bin/test spec/models/subscription_plan_spec.rb

# 4. REFACTOR if needed
```

### Example 2: Adding a Service

```ruby
# 1. RED: Write failing test
# spec/services/user_management/user_creator_spec.rb
RSpec.describe UserManagement::UserCreator do
  describe '#call' do
    let(:params) { { email: 'user@example.com', password: 'password123' } }
    let(:service) { described_class.new(params) }
    
    context 'with valid params' do
      it 'creates a user' do
        expect {
          service.call
        }.to change(User, :count).by(1)
      end
      
      it 'returns success result' do
        result = service.call
        
        expect(result.success?).to be true
        expect(result.user).to be_persisted
      end
    end
    
    context 'with invalid params' do
      let(:params) { { email: 'invalid' } }
      
      it 'returns failure result' do
        result = service.call
        
        expect(result.success?).to be false
        expect(result.errors).to be_present
      end
    end
  end
end

# 2. GREEN: Write service
# app/services/user_management/user_creator.rb
class UserManagement::UserCreator
  attr_reader :params, :result
  
  def initialize(params)
    @params = params
  end
  
  def call
    user = User.new(params)
    
    if user.save
      Result.success(user: user)
    else
      Result.failure(errors: user.errors.full_messages)
    end
  end
end

# 3. REFACTOR: Add result class
```

### Example 3: Controller Test (Request Spec)

```ruby
# 1. RED: Write failing test
# spec/requests/admin/users_spec.rb
RSpec.describe 'Admin::Users', type: :request do
  let(:admin_user) { create(:user, role: :admin) }
  
  before do
    sign_in admin_user
  end
  
  describe 'GET /admin/users' do
    it 'returns list of users' do
      create_list(:user, 3)
      
      get admin_users_path
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Users')
    end
  end
  
  describe 'POST /admin/users' do
    let(:user_params) { { email: 'new@example.com', password: 'password123' } }
    
    context 'with valid params' do
      it 'creates a new user' do
        expect {
          post admin_users_path, params: { user: user_params }
        }.to change(User, :count).by(1)
        
        expect(response).to redirect_to(admin_users_path)
      end
    end
  end
end

# 2. GREEN: Implement controller
# 3. REFACTOR if needed
```

## Best Practices

### DO ✅

- **Always write tests first** when adding new features
- **Keep tests fast** - use `test_fast` for frequent runs
- **Use factories** instead of creating objects manually
- **Test behavior, not implementation**
- **Use descriptive test names**
- **Group related tests with `context`**
- **Use `let` for lazy-loaded test data**
- **Keep tests DRY** with shared examples
- **Run tests before committing**

### DON'T ❌

- **Don't test framework code** (Rails validations, associations unless complex)
- **Don't use `instance_double` everywhere** - use factories when possible
- **Don't write tests for simple getters/setters**
- **Don't create test databases manually** - use factories
- **Don't test private methods** directly
- **Don't write tests that depend on test order**
- **Don't ignore failing tests**

## Test Coverage Goals

### Current Status

```
Models:      ~50%  (12/24)
Controllers:  0%   (0/34)
Services:    ~14%  (3/21)
Helpers:     ~5%   (minimal)

Overall: 10.42%
```

### Phase 1 (Week 1): Critical Path

**Target: 40% coverage**

- [ ] SubscriptionPlan model
- [ ] AccountClaim model
- [ ] Attendance model
- [ ] Core admin controllers (3 specs)
- [ ] Core services (4 specs)

### Phase 2 (Week 2): Admin Complete

**Target: 60% coverage**

- [ ] All admin controllers
- [ ] All payment/membership/event services

### Phase 3 (Week 3): Public Area

**Target: 80% coverage**

- [ ] All public controllers
- [ ] Remaining models
- [ ] Integration tests

## Continuous Integration

### Pre-commit

```bash
# Run before each commit
bin/test_fast        # Quick sanity check
```

### Pre-push

```bash
# CI/CD will run full suite
bin/test             # Full test suite with coverage
```

### Branch Protection

- `dev` branch: All tests must pass
- `staging` branch: All tests + coverage threshold
- `main` branch: All tests + deployment tests

## Troubleshooting

### Tests are slow

```bash
# Use fast tests during development
bin/test_fast

# Run only changed files
bundle exec rspec $(git diff --name-only HEAD | grep _spec.rb)
```

### Tests are flaky

```bash
# Run with specific seed
bundle exec rspec --seed 1234

# Run multiple times
for i in {1..10}; do bundle exec rspec; done
```

### Coverage is low

```bash
# View detailed coverage report
open coverage/index.html

# Focus on untested files first
# See docs/TEST_AUDIT_REPORT.md
```

## Resources

- [RSpec Rails](https://github.com/rspec/rspec-rails)
- [FactoryBot](https://github.com/thoughtbot/factory_bot_rails)
- [Shoulda Matchers](https://github.com/thoughtbot/shoulda-matchers)
- [SimpleCov](https://github.com/simplecov-ruby/simplecov)
- [Better Specs](https://www.betterspecs.org/)

---

**Remember:** Tests are not a burden, they're your safety net! 🎪

