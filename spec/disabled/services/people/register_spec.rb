require 'rails_helper'

RSpec.describe People::Register, type: :service do
  describe '#call' do
    let(:valid_params) do
      {
        first_name: 'John',
        last_name: 'Doe',
        email: 'john.doe@example.com',
        phone: '+33123456789',
        create_user_account: false
      }
    end

    context 'with valid parameters' do
      it 'creates a person successfully' do
        service = described_class.new(valid_params)
        result = service.call

        expect(result.success?).to be true
        expect(result.person).to be_persisted
        expect(result.person.full_name).to eq('John Doe')
        expect(result.person.email).to eq('john.doe@example.com')
      end

      it 'does not create user account when create_user_account is false' do
        service = described_class.new(valid_params)
        result = service.call

        expect(result.user).to be_nil
      end

      it 'creates user account when create_user_account is true' do
        params_with_user = valid_params.merge(
          create_user_account: true,
          user_password: 'password123'
        )
        
        service = described_class.new(params_with_user)
        result = service.call

        expect(result.success?).to be true
        expect(result.user).to be_persisted
        expect(result.user.person).to eq(result.person)
      end
    end

    context 'with invalid parameters' do
      it 'fails when first_name is missing' do
        service = described_class.new(valid_params.except(:first_name))
        result = service.call

        expect(result.success?).to be false
        expect(result.message).to include('Invalid data')
      end

      it 'fails when last_name is missing' do
        service = described_class.new(valid_params.except(:last_name))
        result = service.call

        expect(result.success?).to be false
        expect(result.message).to include('Invalid data')
      end

      it 'fails when email is not unique' do
        create(:person, email: 'john.doe@example.com')
        service = described_class.new(valid_params)
        result = service.call

        expect(result.success?).to be false
        expect(result.message).to include('Invalid data')
      end

      it 'fails when phone is not unique' do
        create(:person, phone: '+33123456789')
        service = described_class.new(valid_params)
        result = service.call

        expect(result.success?).to be false
        expect(result.message).to include('Invalid data')
      end

      it 'fails when create_user_account is true but password is missing' do
        params_without_password = valid_params.merge(create_user_account: true)
        service = described_class.new(params_without_password)
        result = service.call

        expect(result.success?).to be false
        expect(result.message).to include('Invalid data')
      end
    end

    context 'with additional attributes' do
      it 'sets all provided attributes' do
        extended_params = valid_params.merge(
          address: '123 Main St',
          birth_date: 25.years.ago.to_date,
          emergency_contact_name: 'Jane Doe',
          emergency_contact_phone: '+33987654321',
          notes: 'Test notes',
          occupation: 'Developer',
          specialty: 'Ruby',
          image_rights: true,
          get_involved: true,
          newsletter_subscribed: true,
          dyslexic_font: false
        )

        service = described_class.new(extended_params)
        result = service.call

        expect(result.success?).to be true
        person = result.person
        expect(person.address).to eq('123 Main St')
        expect(person.occupation).to eq('Developer')
        expect(person.image_rights).to be true
        expect(person.get_involved).to be true
      end
    end
  end
end
