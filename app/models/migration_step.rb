class MigrationStep < ApplicationRecord
  # Associations
  belongs_to :migration_plan
  belongs_to :dependee, class_name: 'MigrationStep', optional: true
  has_many :dependents, class_name: 'MigrationStep', foreign_key: :dependee_id

  # Enums
  enum attachment_export_mode: {
    ignore: 0,
    url: 1,
    raw_data: 2
  }

  # Validations
  validates :source_model_name, presence: true
  validates :sequence, presence: true, numericality: { only_integer: true }
  validate :validate_json_field_types

  # Callbacks to set defaults
  after_initialize :set_defaults, if: :new_record?
  before_validation :parse_json_fields

  # Scopes
  scope :ordered_by_sequence, -> { order(:sequence) }

  # Custom getter for dependee_attribute_mapping
  def dependee_attribute_mapping
    value = read_attribute(:dependee_attribute_mapping)
    return {} if value.blank?
    return value if value.is_a?(Hash)
    JSON.parse(value)
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse dependee_attribute_mapping for MigrationStep #{id}: #{e.message}"
    {}
  end

  # Custom setter for dependee_attribute_mapping
  def dependee_attribute_mapping=(value)
    if value.is_a?(String)
      write_attribute(:dependee_attribute_mapping, value)
    elsif value.is_a?(Hash)
      write_attribute(:dependee_attribute_mapping, value.to_json)
    else
      write_attribute(:dependee_attribute_mapping, {}.to_json)
    end
  end

  # Custom getter for column_overrides
  def column_overrides
    value = read_attribute(:column_overrides)
    return {} if value.blank?
    return value if value.is_a?(Hash)
    JSON.parse(value)
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse column_overrides for MigrationStep #{id}: #{e.message}"
    {}
  end

  # Custom setter for column_overrides
  def column_overrides=(value)
    if value.is_a?(String)
      write_attribute(:column_overrides, value)
    elsif value.is_a?(Hash)
      write_attribute(:column_overrides, value.to_json)
    else
      write_attribute(:column_overrides, {}.to_json)
    end
  end

  # Custom getter for association_overrides
  def association_overrides
    value = read_attribute(:association_overrides)
    return {} if value.blank?
    return value if value.is_a?(Hash)
    JSON.parse(value)
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse association_overrides for MigrationStep #{id}: #{e.message}"
    {}
  end

  # Custom setter for association_overrides
  def association_overrides=(value)
    if value.is_a?(String)
      write_attribute(:association_overrides, value)
    elsif value.is_a?(Hash)
      write_attribute(:association_overrides, value.to_json)
    else
      write_attribute(:association_overrides, {}.to_json)
    end
  end

  private

  def set_defaults
    self.dependee_attribute_mapping ||= {}
    self.column_overrides ||= {}
    self.association_overrides ||= {}
  end

  def parse_json_fields
    # Parse JSON string fields into proper objects
    json_fields = %i[
      dependee_attribute_mapping
      column_overrides
      association_overrides
    ]

    json_fields.each do |field|
      value = send(field)
      next if value.blank?

      # If it's a string, try to parse it as JSON
      if value.is_a?(String)
        begin
          parsed_value = JSON.parse(value)
          send("#{field}=", parsed_value)
        rescue JSON::ParserError => e
          # Add validation error for invalid JSON
          errors.add(field, "contains invalid JSON: #{e.message}")
        end
      end
    end
  end

  def validate_json_field_types
    # Ensure JSON fields are objects (Hash), not arrays
    json_fields = {
      dependee_attribute_mapping: 'Dependee Attribute Mapping',
      column_overrides: 'Column Overrides',
      association_overrides: 'Association ID Mappings'
    }

    json_fields.each do |field, label|
      value = send(field)
      next if value.blank? || value == {}

      # Check if it's a Hash (JSON object)
      if value.is_a?(Array)
        errors.add(field, "#{label} must be a JSON object {}, not an array []")
      elsif !value.is_a?(Hash)
        errors.add(field, "#{label} must be a valid JSON object")
      end
    end
  end
end
