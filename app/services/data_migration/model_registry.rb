# frozen_string_literal: true

module DataMigration
  class ModelRegistry
    CACHE_KEY = 'data_migration_model_registry'
    CACHE_EXPIRY = 1.hour

    class << self
      def all_models
        Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_EXPIRY) do
          load_models
        end
      end

      def model_metadata(model_name)
        all_models[model_name]
      end

      def model_names
        all_models.keys.sort
      end

      def refresh!
        Rails.cache.delete(CACHE_KEY)
        all_models
      end

      private

      def load_models
        models_data = {}

        # Ensure all models are loaded
        Rails.application.eager_load! unless Rails.application.config.eager_load

        ActiveRecord::Base.descendants.each do |model|
          # Skip engine models, abstract classes, and internal Rails models
          next if model.name.nil?
          next if model.name.start_with?('DataMigration', 'ActiveStorage', 'ApplicationRecord')
          next if model.abstract_class?

          begin
            models_data[model.name] = extract_model_metadata(model)
          rescue StandardError => e
            Rails.logger.warn "Failed to extract metadata for #{model.name}: #{e.message}"
          end
        end

        models_data
      end

      def extract_model_metadata(model)
        metadata = {
          name: model.name,
          table_name: model.table_name,
          columns: [],
          attachments: [],
          associations: {}
        }

        # Extract column information
        model.columns.each do |column|
          metadata[:columns] << {
            name: column.name,
            type: column.type.to_s,
            sql_type: column.sql_type
          }
        end

        # Extract Active Storage attachments
        if model.respond_to?(:reflect_on_all_attachments)
          model.reflect_on_all_attachments.each do |attachment|
            metadata[:attachments] << {
              name: attachment.name.to_s,
              type: attachment.macro.to_s # :has_one_attached or :has_many_attached
            }
          end
        end

        # Extract associations
        model.reflect_on_all_associations.each do |association|
          next if association.class_name.start_with?('ActiveStorage', 'DataMigration')

          metadata[:associations][association.name.to_s] = {
            type: association.macro.to_s,
            class_name: association.class_name,
            foreign_key: association.foreign_key
          }
        end

        metadata
      end
    end
  end
end
