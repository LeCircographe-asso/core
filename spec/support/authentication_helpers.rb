module AuthenticationHelpers
  def login_as(user)
    @current_session = user.sessions.create!(
      user_agent: "Mozilla/5.0",
      ip_address: "127.0.0.1"
    )
    Current.session = @current_session
  end

  def logout
    @current_session&.destroy
    Current.session = nil
    @current_session = nil
  end

  def current_user
    Current.user
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
  config.include AuthenticationHelpers, type: :controller
  
  # Stub Authentication#find_session_by_cookie to use our test session
  config.before(:each, type: :request) do
    allow_any_instance_of(Authentication).to receive(:find_session_by_cookie) do
      @current_session if defined?(@current_session)
    end
  end
  
  # Reset Current.session after each test
  config.after do
    logout
  end
end

