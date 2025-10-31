class NewsletterSubscriber < ApplicationRecord
  belongs_to :person, optional: true
  
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :unsubscribe_token, uniqueness: true, allow_nil: true
  
  before_validation :normalize_email
  before_create :generate_unsubscribe_token
  before_create :set_subscribed_at
  
  scope :subscribed, -> { where(subscribed: true) }
  scope :unsubscribed, -> { where(subscribed: false) }
  scope :orphaned, -> { where(person_id: nil) }
  scope :linked, -> { where.not(person_id: nil) }
  
  def unsubscribe!
    update!(subscribed: false, unsubscribed_at: Time.current)
  end
  
  def resubscribe!
    update!(subscribed: true, subscribed_at: Time.current, unsubscribed_at: nil)
  end
  
  # Merge vers Person existante
  def link_to_person!(person)
    transaction do
      update!(person_id: person.id)
      person.update!(newsletter_subscribed: true) if subscribed?
    end
  end
  
  private
  
  def normalize_email
    self.email = email&.strip&.downcase
  end
  
  def generate_unsubscribe_token
    self.unsubscribe_token ||= SecureRandom.urlsafe_base64(32)
  end
  
  def set_subscribed_at
    self.subscribed_at ||= Time.current if subscribed?
  end
end

