class BookOfEntry < ApplicationRecord
  belongs_to :product
  belongs_to :user

  enum :status, %i[inactive active], default: :active

  after_create :bookOfEntryValidation 

  def bookOfEntryValidation
    erreurs = []

    if self.product_id.blank?
      erreurs << "Le produit est obligatoire"
    end

    if self.user_id.blank?
      erreurs << "L'utilisateur est obligatoire"
    end
  end
end
