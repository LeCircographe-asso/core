# Legacy Adapter pour compatibilité avec l'ancien système Product/Order
# Permet de présenter MembershipType et SubscriptionPlan comme des Product
# pour maintenir la compatibilité avec les vues existantes

module Legacy
  class ProductAdapter
    include ActiveModel::Model
    include ActiveModel::Attributes

    # Attributs pour simuler un Product
    attribute :id, :integer
    attribute :product_name, :string
    attribute :product_type, :string
    attribute :price_cents, :integer
    attribute :created_at, :datetime
    attribute :updated_at, :datetime

    # Objet source (MembershipType ou SubscriptionPlan)
    attr_accessor :source_object

    # Factory methods pour créer des adapters
    def self.from_membership_type(membership_type)
      new(
        id: membership_type.id,
        product_name: membership_type.name,
        product_type: "adhesion",
        price_cents: membership_type.price_cents,
        created_at: membership_type.created_at,
        updated_at: membership_type.updated_at,
        source_object: membership_type
      )
    end

    def self.from_subscription_plan(subscription_plan)
      new(
        id: subscription_plan.id + 10000, # Offset pour éviter les conflits d'ID
        product_name: subscription_plan.name,
        product_type: "cotisation",
        price_cents: subscription_plan.price_cents,
        created_at: subscription_plan.created_at,
        updated_at: subscription_plan.updated_at,
        source_object: subscription_plan
      )
    end

    # Méthodes pour compatibilité avec l'ancien modèle Product
    def display_name
      case product_type
      when "adhesion"
        product_name.gsub(/^Adhésion\s+/, "")
      when "cotisation"
        product_name.gsub(/^Cotisation\s+/, "")
      else
        product_name
      end
    end

    def category_name
      case product_type
      when "adhesion"
        "Adhésion"
      when "cotisation"
        "Cotisation"
      else
        product_type.to_s.capitalize
      end
    end

    def price_euros
      price_cents / 100.0
    end

    def price_euros=(value)
      self.price_cents = (value.to_f * 100).round
    end

    # Méthodes pour simuler les relations ActiveRecord
    def persisted?
      true
    end

    def new_record?
      false
    end

    def destroyed?
      false
    end

    def to_param
      id.to_s
    end

    # Méthodes de classe pour simuler les scopes
    def self.where(conditions = {})
      results = []
      
      if conditions[:product_type] == "adhesion" || conditions[:product_type].nil?
        MembershipType.all.each do |mt|
          results << from_membership_type(mt)
        end
      end
      
      if conditions[:product_type] == "cotisation" || conditions[:product_type].nil?
        SubscriptionPlan.all.each do |sp|
          results << from_subscription_plan(sp)
        end
      end
      
      # Filtrer par conditions supplémentaires
      if conditions[:id]
        results = results.select { |p| p.id == conditions[:id] }
      end
      
      results
    end

    def self.find(id)
      # Chercher d'abord dans MembershipType
      if membership_type = MembershipType.find_by(id: id)
        return from_membership_type(membership_type)
      end
      
      # Chercher dans SubscriptionPlan avec offset
      if subscription_plan = SubscriptionPlan.find_by(id: id - 10000)
        return from_subscription_plan(subscription_plan)
      end
      
      raise ActiveRecord::RecordNotFound, "Couldn't find Product with 'id'=#{id}"
    end

    def self.all
      results = []
      MembershipType.all.each { |mt| results << from_membership_type(mt) }
      SubscriptionPlan.all.each { |sp| results << from_subscription_plan(sp) }
      results
    end

    def self.count
      MembershipType.count + SubscriptionPlan.count
    end

    # Méthodes pour compatibilité avec les vues
    def adhesion?
      product_type == "adhesion"
    end

    def cotisation?
      product_type == "cotisation"
    end

    # Méthodes pour simuler les relations
    def book_of_entries
      if source_object.is_a?(MembershipType)
        # Pour les adhésions, retourner les book_of_entries liés aux membres
        BookOfEntry.joins(:person => :memberships)
                   .where(memberships: { membership_type: source_object })
      else
        # Pour les cotisations, retourner les book_of_entries liés au plan
        source_object.book_of_entries
      end
    end

    def price_entries
      # Retourner une collection vide pour compatibilité
      []
    end

    def product_orders
      # Retourner une collection vide pour compatibilité
      []
    end
  end
end
