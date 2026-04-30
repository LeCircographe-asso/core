# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MemberManagementService do
  describe '.generate_member_number' do
    it 'generates member number in correct format' do
      number = MemberManagementService.generate_member_number('U')
      expect(number).to match(/^\d{2}U\d{3}$/)
    end

    it 'generates member number with current year' do
      current_year = Date.current.year.to_s.last(2)
      number = MemberManagementService.generate_member_number('U')
      expect(number).to start_with(current_year)
    end

    it "generates 'U' type for basic membership" do
      number = MemberManagementService.generate_member_number('BASIQUE')
      expect(number).to match(/^\d{2}U\d{3}$/)
    end

    it "generates 'C' type for circus membership" do
      # Create a person with a circus member number to ensure correct generation
      create(:person, member_number: '25C001')

      number = MemberManagementService.generate_member_number('CIRQUE')
      expect(number).to match(/^\d{2}C\d{3}$/)
    end

    it 'generates sequential numbers' do
      # Create a person with a member number to ensure sequential generation
      create(:person, member_number: '25U001')

      number1 = MemberManagementService.generate_member_number('U')
      # Create Person with number1 to force next generation to be sequential
      create(:person, member_number: number1)
      number2 = MemberManagementService.generate_member_number('U')

      expect(number1).not_to eq(number2)

      # Extract numbers from format YYTNNN
      num1 = number1.gsub(/^\d{2}U/, '').to_i
      num2 = number2.gsub(/^\d{2}U/, '').to_i

      # The second number should be greater than the first
      expect(num2).to be > num1
    end

    it 'avoids conflicts with existing numbers' do
      # Create a person with a specific number
      create(:person, member_number: '25U001')

      # Generate new number - should not conflict with existing
      number = MemberManagementService.generate_member_number('U')

      expect(number).not_to eq('25U001')
      # Verify uniqueness
      expect(Person.exists?(member_number: number)).to be false
      expect(MemberNumberHistory.exists?(member_number: number)).to be false
    end

    it 'handles different membership types separately' do
      number_u = MemberManagementService.generate_member_number('U')
      number_c = MemberManagementService.generate_member_number('C')

      expect(number_u).to match(/^\d{2}U\d{3}$/)
      expect(number_c).to match(/^\d{2}C\d{3}$/)
    end
  end

  describe '.assign_member_number' do
    let(:person) { create(:person) }

    it 'assigns member number to person' do
      result = MemberManagementService.assign_member_number(person)

      expect(result).to be_present
      expect(person.reload.member_number).to eq(result)
      expect(result).to match(/^\d{2}[UC]\d{3}$/)
    end

    it 'returns existing member number if already assigned' do
      person.update!(member_number: '25U001', skip_membership_validation: true)

      result = MemberManagementService.assign_member_number(person)

      expect(result).to eq('25U001')
    end

    it 'determines membership type from active membership' do
      membership_type = create(:membership_type, category: :circus)
      create(:membership, person: person, membership_type: membership_type, status: :active)

      result = MemberManagementService.assign_member_number(person)

      expect(result).to match(/^\d{2}C\d{3}$/)
    end

    it 'uses basic type for basic membership' do
      membership_type = create(:membership_type, category: :basic)
      create(:membership, person: person, membership_type: membership_type, status: :active)

      result = MemberManagementService.assign_member_number(person)

      expect(result).to match(/^\d{2}U\d{3}$/)
    end

    it "uses 'U' as default when no active membership" do
      result = MemberManagementService.assign_member_number(person)

      expect(result).to match(/^\d{2}U\d{3}$/)
    end

    it 'creates member number history' do
      expect do
        MemberManagementService.assign_member_number(person)
      end.to change(person.member_number_histories, :count).by(1)

      history = person.member_number_histories.first
      expect(history.member_number).to eq(person.member_number)
      expect(history.membership_type).to eq('Basique')
      expect(history.year).to eq(Date.current.year)
      expect(history.notes).to eq("Numéro d'adhérent initial")
    end

    it 'skips membership validation during assignment' do
      # Remove any existing memberships
      person.memberships.destroy_all

      expect do
        MemberManagementService.assign_member_number(person)
      end.not_to raise_error

      expect(person.reload.member_number).to be_present
    end
  end

  describe '.merge_duplicate_persons' do
    let(:primary_person) { create(:person, email: 'primary@example.com', phone: '1111111111') }
    let(:secondary_person) { create(:person, email: 'secondary@example.com', phone: '2222222222') }

    before do
      # Create some associated records
      create(:membership, person: secondary_person)
      create(:payment, person: secondary_person)
      create(:attendance, person: secondary_person)
    end

    it 'merges persons successfully' do
      result = MemberManagementService.merge_duplicate_persons(primary_person, secondary_person)

      expect(result[:success]).to be true
      expect(result[:primary_person]).to eq(primary_person)
      expect(result[:transferred_count]).to eq(3) # membership + payment + attendance
    end

    it 'transfers email from secondary to primary' do
      primary_person.update!(email: nil, newsletter_subscribed: false, skip_membership_validation: true)

      result = MemberManagementService.merge_duplicate_persons(primary_person, secondary_person)

      expect(result[:success]).to be true
      expect(primary_person.reload.email).to eq('secondary@example.com')
      expect(result[:merged_fields]).to include(:email)
    end

    it 'transfers phone from secondary to primary' do
      primary_person.update!(phone: nil, skip_membership_validation: true)

      result = MemberManagementService.merge_duplicate_persons(primary_person, secondary_person)

      expect(result[:success]).to be true
      expect(primary_person.reload.phone).to eq('2222222222')
      expect(result[:merged_fields]).to include(:phone)
    end

    it 'transfers address information' do
      primary_person.update!(address: nil, zip_code: nil, town: nil, country: nil, skip_membership_validation: true)
      secondary_person.update!(
        address: '123 Test St',
        zip_code: '12345',
        town: 'Test City',
        country: 'France',
        skip_membership_validation: true
      )

      result = MemberManagementService.merge_duplicate_persons(primary_person, secondary_person)

      expect(result[:success]).to be true
      expect(primary_person.reload.address).to eq('123 Test St')
      expect(primary_person.zip_code).to eq('12345')
      expect(primary_person.town).to eq('Test City')
      expect(primary_person.country).to eq('France')
      expect(result[:merged_fields]).to include(:address, :zip_code, :town, :country)
    end

    it 'transfers all related records' do
      MemberManagementService.merge_duplicate_persons(primary_person, secondary_person)

      # Check that records were transferred
      expect(primary_person.reload.memberships.count).to eq(1)
      expect(primary_person.payments.count).to eq(1)
      expect(primary_person.attendances.count).to eq(1)

      # Check that secondary person no longer exists
      expect { secondary_person.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'handles errors gracefully' do
      primary_person.update!(email: nil, skip_membership_validation: true)
      # Make the merge fail by causing a validation error
      allow(primary_person).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(primary_person))

      result = MemberManagementService.merge_duplicate_persons(primary_person, secondary_person)

      expect(result[:success]).to be false
      expect(result[:error]).to be_present
    end

    it 'performs merge in transaction' do
      # If any part fails, everything should be rolled back
      allow(secondary_person).to receive(:destroy!).and_raise(ActiveRecord::RecordInvalid.new(secondary_person))

      result = MemberManagementService.merge_duplicate_persons(primary_person, secondary_person)

      expect(result[:success]).to be false
      # Both persons should still exist (rollback)
      expect { primary_person.reload }.not_to raise_error
      expect { secondary_person.reload }.not_to raise_error
      # Verify nothing was transferred
      expect(primary_person.reload.memberships.count).to eq(0)
    end
  end

  describe '.identify_duplicates' do
    it 'identifies name duplicates' do
      person1 = create(:person, first_name: 'John', last_name: 'Doe')
      person2 = create(:person, first_name: 'John', last_name: 'Doe')
      create(:person, first_name: 'Jane', last_name: 'Smith')

      duplicates = MemberManagementService.identify_duplicates

      expect(duplicates.length).to eq(1)
      expect(duplicates.first[:type]).to eq(:name_duplicate)
      expect(duplicates.first[:primary_person]).to be_in([person1, person2])
      primary = duplicates.first[:primary_person]
      others = ([person1, person2] - [primary])
      expect(duplicates.first[:secondary_persons]).to contain_exactly(*others)
    end

    it 'selects person with user account as primary' do
      person_without_user = create(:person, first_name: 'John', last_name: 'Doe')
      person_with_user = create(:person, first_name: 'John', last_name: 'Doe')
      create(:user, person: person_with_user)

      duplicates = MemberManagementService.identify_duplicates

      expect(duplicates.first[:primary_person]).to eq(person_with_user)
      expect(duplicates.first[:secondary_persons]).to contain_exactly(person_without_user)
    end

    it 'selects most recent person as primary when no user accounts' do
      older_person = create(:person, first_name: 'John', last_name: 'Doe', created_at: 2.days.ago)
      newer_person = create(:person, first_name: 'John', last_name: 'Doe', created_at: 1.day.ago)

      duplicates = MemberManagementService.identify_duplicates

      expect(duplicates.first[:primary_person]).to eq(newer_person)
      expect(duplicates.first[:secondary_persons]).to contain_exactly(older_person)
    end

    it 'does not identify single persons as duplicates' do
      create(:person, first_name: 'John', last_name: 'Doe')

      duplicates = MemberManagementService.identify_duplicates

      expect(duplicates).to be_empty
    end
  end

  describe '.cleanup_duplicates' do
    it 'cleans up all identified duplicates' do
      create(:person, first_name: 'John', last_name: 'Doe')
      create(:person, first_name: 'John', last_name: 'Doe')
      create(:person, first_name: 'Jane', last_name: 'Smith')
      create(:person, first_name: 'Jane', last_name: 'Smith')

      results = MemberManagementService.cleanup_duplicates

      expect(results.length).to eq(2) # Two groups of duplicates
      expect(results.all? { |r| r[:result][:success] }).to be true
    end

    it 'handles cleanup errors gracefully' do
      create(:person, first_name: 'John', last_name: 'Doe')
      create(:person, first_name: 'John', last_name: 'Doe')

      # Make the merge fail
      allow(MemberManagementService).to receive(:merge_duplicate_persons).and_return({ success: false, error: 'Test error' })

      results = MemberManagementService.cleanup_duplicates

      expect(results.length).to eq(1)
      expect(results.first[:result][:success]).to be false
      expect(results.first[:result][:error]).to eq('Test error')
    end
  end

  describe '.assign_missing_member_numbers' do
    before do
      # Clean up any persons without member numbers from previous tests
      Person.where(member_number: [nil, '']).destroy_all
    end

    it 'assigns numbers to persons without member numbers' do
      person1 = create(:person, member_number: nil)
      person2 = create(:person, member_number: '')
      person3 = create(:person, member_number: '25U001') # Already has number

      expect do
        MemberManagementService.assign_missing_member_numbers
      end.to change { Person.where(member_number: [nil, '']).count }.by(-2)

      expect(person1.reload.member_number).to be_present
      expect(person2.reload.member_number).to be_present
      expect(person3.reload.member_number).to eq('25U001') # Unchanged
    end
  end

  describe '.parse_member_number' do
    it 'parses valid member number' do
      result = MemberManagementService.parse_member_number('25U001')

      expect(result).to eq({
                             year: '2025',
                             type: 'Basique',
                             number: 1,
                             full_year: '25',
                             type_code: 'U'
                           })
    end

    it 'parses circus member number' do
      result = MemberManagementService.parse_member_number('25C001')

      expect(result).to eq({
                             year: '2025',
                             type: 'Cirque',
                             number: 1,
                             full_year: '25',
                             type_code: 'C'
                           })
    end

    it 'returns nil for invalid format' do
      result = MemberManagementService.parse_member_number('invalid')
      expect(result).to be_nil
    end

    it 'returns nil for nil input' do
      result = MemberManagementService.parse_member_number(nil)
      expect(result).to be_nil
    end

    it 'returns nil for empty string' do
      result = MemberManagementService.parse_member_number('')
      expect(result).to be_nil
    end
  end

  describe '.valid_member_number_format?' do
    it 'validates correct format' do
      expect(MemberManagementService.valid_member_number_format?('25U001')).to be true
      expect(MemberManagementService.valid_member_number_format?('25C999')).to be true
      expect(MemberManagementService.valid_member_number_format?('25U1234')).to be true # 4 digits
      expect(MemberManagementService.valid_member_number_format?('25U12345')).to be true # 5 digits
    end

    it 'rejects invalid format' do
      expect(MemberManagementService.valid_member_number_format?('25X001')).to be false # Wrong type code
      expect(MemberManagementService.valid_member_number_format?('25U01')).to be false # Too short
      expect(MemberManagementService.valid_member_number_format?('25U123456')).to be false # Too long
      expect(MemberManagementService.valid_member_number_format?('invalid')).to be false
      expect(MemberManagementService.valid_member_number_format?(nil)).to be false
      expect(MemberManagementService.valid_member_number_format?('')).to be false
    end
  end

  describe '.generate_test_numbers' do
    it 'generates specified number of test numbers' do
      numbers = MemberManagementService.generate_test_numbers(3, 'U')

      expect(numbers.length).to eq(3)
      numbers.each do |number|
        expect(number).to match(/^\d{2}U\d{3}$/)
      end
    end

    it 'generates sequential test numbers' do
      # Create a person with a circus member number to ensure correct generation
      create(:person, member_number: '25C001')

      numbers = MemberManagementService.generate_test_numbers(3, 'C')

      expect(numbers.length).to eq(3)
      numbers.each do |number|
        expect(number).to match(/^\d{2}C\d{3}$/)
      end

      # Check they are sequential
      num1 = numbers[0].gsub(/^\d{2}C/, '').to_i
      num2 = numbers[1].gsub(/^\d{2}C/, '').to_i
      num3 = numbers[2].gsub(/^\d{2}C/, '').to_i

      expect(num2).to be > num1
      expect(num3).to be > num2
    end
  end
end
