module MigrationPlans
  class ExportConfigService
    attr_reader :migration_plan

    def initialize(migration_plan)
      @migration_plan = migration_plan
    end

    def call
      {
        version: '1.0',
        exported_at: Time.current.iso8601,
        plan: {
          name: migration_plan.name,
          description: migration_plan.description,
          steps: export_steps
        }
      }.to_json
    end

    private

    def export_steps
      migration_plan.migration_steps.order(:sequence).map do |step|
        {
          source_model_name: step.source_model_name,
          sequence: step.sequence,
          filter_query: step.filter_query,
          column_overrides: step.column_overrides,
          association_overrides: step.association_overrides,
          attachment_export_mode: step.attachment_export_mode,
          attachment_fields: step.attachment_fields,
          dependee_sequence: step.dependee&.sequence, # Reference by sequence, not ID
          dependee_attribute_mapping: step.dependee_attribute_mapping
        }
      end
    end
  end
end