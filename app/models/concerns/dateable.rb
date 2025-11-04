module Dateable
  extend ActiveSupport::Concern

  # Méthodes de formatage de dates
  def formatted_date(date_attr = :created_at)
    date = send(date_attr)
    return "Non renseigné" unless date

    date.strftime("%d/%m/%Y")
  end

  def formatted_datetime(date_attr = :created_at)
    date = send(date_attr)
    return "Non renseigné" unless date

    date.strftime("%d/%m/%Y à %H:%M")
  end

  def formatted_time(date_attr = :created_at)
    date = send(date_attr)
    return "Non renseigné" unless date

    date.strftime("%H:%M")
  end

  # Méthodes de vérification de dates
  def today?(date_attr = :created_at)
    date = send(date_attr)
    return false unless date

    date.to_date == Date.current
  end

  def this_week?(date_attr = :created_at)
    date = send(date_attr)
    return false unless date

    date.to_date >= Date.current.beginning_of_week && 
    date.to_date <= Date.current.end_of_week
  end

  def this_month?(date_attr = :created_at)
    date = send(date_attr)
    return false unless date

    date.to_date >= Date.current.beginning_of_month && 
    date.to_date <= Date.current.end_of_month
  end

  def this_year?(date_attr = :created_at)
    date = send(date_attr)
    return false unless date

    date.year == Date.current.year
  end

  # Méthodes de calcul de durée
  def duration_days(start_attr = :started_at, end_attr = :ended_at)
    start_date = send(start_attr)
    end_date = send(end_attr)
    return nil unless start_date && end_date

    (end_date.to_date - start_date.to_date).to_i
  end

  def duration_months(start_attr = :started_at, end_attr = :ended_at)
    start_date = send(start_attr)
    end_date = send(end_attr)
    return nil unless start_date && end_date

    (end_date.year - start_date.year) * 12 + (end_date.month - start_date.month)
  end

  # Méthodes de classe pour les scopes temporels
  class_methods do
    def today(date_attr = nil)
      # Auto-detect date attribute: prefer :date if it exists, otherwise :created_at
      if date_attr.nil?
        # Check if model has a 'date' column and it's a date type (not datetime)
        if columns_hash.key?('date') && columns_hash['date'].type == :date
          date_attr = :date
        else
          date_attr = :created_at
        end
      end
      
      # For date columns, use simple equality; for datetime columns, use range
      if date_attr == :date && columns_hash.key?('date') && columns_hash['date'].type == :date
        where(date: Date.current)
      else
        where("#{date_attr} >= ? AND #{date_attr} < ?", 
              Date.current.beginning_of_day, 
              Date.current.end_of_day)
      end
    end

    def this_week(date_attr = nil)
      # Auto-detect date attribute: prefer :date if it exists, otherwise :created_at
      if date_attr.nil?
        if columns_hash.key?('date') && columns_hash['date'].type == :date
          date_attr = :date
        else
          date_attr = :created_at
        end
      end
      
      if date_attr == :date && columns_hash.key?('date') && columns_hash['date'].type == :date
        where(date: Date.current.beginning_of_week..Date.current.end_of_week)
      else
        where("#{date_attr} >= ? AND #{date_attr} <= ?", 
              Date.current.beginning_of_week, 
              Date.current.end_of_week)
      end
    end

    def this_month(date_attr = nil)
      # Auto-detect date attribute: prefer :date if it exists, otherwise :created_at
      if date_attr.nil?
        if columns_hash.key?('date') && columns_hash['date'].type == :date
          date_attr = :date
        else
          date_attr = :created_at
        end
      end
      
      if date_attr == :date && columns_hash.key?('date') && columns_hash['date'].type == :date
        where(date: Date.current.beginning_of_month..Date.current.end_of_month)
      else
        where("#{date_attr} >= ? AND #{date_attr} <= ?", 
              Date.current.beginning_of_month, 
              Date.current.end_of_month)
      end
    end

    def this_year(date_attr = :created_at)
      where("#{date_attr} >= ? AND #{date_attr} <= ?", 
            Date.current.beginning_of_year, 
            Date.current.end_of_year)
    end

    def upcoming(date_attr = :date)
      where("#{date_attr} >= ?", Date.current)
    end

    def past(date_attr = :date)
      where("#{date_attr} < ?", Date.current)
    end

    def by_date_range(start_date, end_date, date_attr = :created_at)
      where("#{date_attr} >= ? AND #{date_attr} <= ?", start_date, end_date)
    end
  end
end
