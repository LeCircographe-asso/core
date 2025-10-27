class Admin::DuplicatesController < Admin::BaseController
  def index
    @duplicates = find_duplicates
  end
  
  def merge
    @source_person = Person.find(params[:source_id])
    @target_person = Person.find(params[:target_id])
    
    result = People::Merger.new(
      source: @source_person,
      target: @target_person,
      actor: Current.user
    ).call
    
    if result.success?
      redirect_to admin_users_path, notice: "Fusion réussie : #{@source_person.full_name} → #{@target_person.full_name}"
    else
      redirect_to admin_duplicates_path, alert: result.errors.join(", ")
    end
  end
  
  private
  
  def find_duplicates
    duplicates = []
    
    # Doublons par email
    Person.active.group(:email).having("COUNT(*) > 1").count.each do |email, count|
      next if email.blank?
      duplicates << {
        type: :email,
        value: email,
        people: Person.active.where(email: email),
        count: count
      }
    end
    
    # Doublons par nom+prénom
    Person.active.group(:first_name, :last_name).having("COUNT(*) > 1").count.each do |(first_name, last_name), count|
      duplicates << {
        type: :name,
        value: "#{first_name} #{last_name}",
        people: Person.active.where(first_name: first_name, last_name: last_name),
        count: count
      }
    end
    
    duplicates
  end
end
