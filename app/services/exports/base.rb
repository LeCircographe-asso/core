# frozen_string_literal: true

require "csv"

module Exports
  # Declarative CSV export. Subclasses declare their columns once; headers are
  # stable snake_case keys meant to be read by tools (accounting, re-import).
  #
  # Evolution contract (enforced by the header specs):
  # - append new columns at the end, never rename or reorder existing keys;
  # - any breaking change (rename, removal, semantic change) bumps `version`,
  #   which is part of the filename so downstream consumers notice.
  class Base
    BOM = "﻿"
    FORMULA_PREFIX = /\A[=+\-@\t\r]/
    NUMERIC = /\A-?\d+(\.\d+)?\z/

    Column = Data.define(:key, :value)

    class << self
      attr_reader :version, :period_model, :period_attribute

      def columns
        @columns ||= []
      end

      def headers
        columns.map { |column| column.key.to_s }
      end

      def key
        name.demodulize.underscore
      end

      private

      def export_version(number)
        @version = number
      end

      def column(key, &value)
        columns << Column.new(key:, value:)
      end

      def period_on(model, attribute)
        @period_model = model
        @period_attribute = attribute
      end

      def person_columns(prefix = nil, &resolver)
        name = ->(attribute) { [ prefix, attribute ].compact.join("_").to_sym }
        column(name.call("person_id")) { |record| resolver.call(record)&.id }
        column(name.call("member_number")) { |record| resolver.call(record)&.member_number }
        column(name.call("last_name")) { |record| resolver.call(record)&.last_name }
        column(name.call("first_name")) { |record| resolver.call(record)&.first_name }
      end
    end

    attr_reader :from, :to, :row_count

    def initialize(from: nil, to: nil)
      @from = parse_date(from)
      @to = parse_date(to)
      @row_count = 0
    end

    def filename
      period = [ from, to ].compact.map(&:iso8601).join("_")
      [ self.class.key, "v#{self.class.version}", period.presence, Date.current.iso8601 ].compact.join("_") + ".csv"
    end

    def to_csv
      BOM + CSV.generate do |csv|
        csv << self.class.headers
        relation.find_each do |record|
          csv << self.class.columns.map { |column| cell(instance_exec(record, &column.value)) }
          @row_count += 1
        end
      end
    end

    private

    def scope
      raise NotImplementedError
    end

    def relation
      return scope if from.nil? && to.nil?

      model = self.class.period_model
      attribute = self.class.period_attribute
      scope.where(model.table_name => { attribute => period_for(model, attribute) })
    end

    def period_for(model, attribute)
      return from..to if model.type_for_attribute(attribute.to_s).type == :date

      from&.beginning_of_day..to&.end_of_day
    end

    def parse_date(value)
      return value if value.is_a?(Date)
      return if value.blank?

      Date.iso8601(value.to_s)
    rescue Date::Error
      nil
    end

    def cell(value)
      case value
      when ActiveSupport::TimeWithZone, Time then value.in_time_zone.iso8601
      when Date then value.iso8601
      when String then neutralize_formula(value)
      else value
      end
    end

    # Prevents CSV formula injection when the file is opened in a spreadsheet.
    def neutralize_formula(value)
      return value unless value.match?(FORMULA_PREFIX) && !value.match?(NUMERIC)

      "'#{value}"
    end

    def euros(cents)
      return if cents.nil?

      format("%.2f", cents / 100.0)
    end
  end
end
