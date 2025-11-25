module MigrationPlans
  class ImportConfigService
    attr_reader :config_json, :current_user, :errors

    def initialize(config_json, current_user)
      @config_json = config_json
      @current_user = current_user
      @errors = []
      @step_mapping = {} # Maps sequence to step objects for dependency resolution
    end

    def call
      config = parse_config
      return nil unless config

      validate_config(config)
      return nil if @errors.any?

      create_plan_with_steps(config)
    rescue StandardError => e
      @errors << "Import failed: #{e.message}"
      nil
    end

    def success?
      @errors.empty?
    end

    private

    def parse_config
      JSON.parse(@config_json)
    rescue JSON::ParserError => e
      @errors << "Invalid JSON format: #{e.message}"
      nil
    end

    def validate_config(config)
      unless config['plan']
        @errors << "Missing 'plan' section in configuration"
        return
      end

      plan_data = config['plan']

      unless plan_data['name'].present?
        @errors << "Plan name is required"
      end

      unless plan_data['steps'].is_a?(Array)
        @errors << "Steps must be an array"
        return
      end

      # Validate each step
      plan_data['steps'].each_with_index do |step_data, index|
        validate_step(step_data, index)
      end
    end

    def validate_step(step_data, index)
      unless step_data['source_model_name'].present?
        @errors << "Step #{index + 1}: source_model_name is required"
        return
      end

      # Check if model exists in this environment
      begin
        step_data['source_model_name'].constantize
      rescue NameError
        @errors << "Step #{index + 1}: Model '#{step_data['source_model_name']}' not found in this environment"
      end

      unless step_data['sequence'].present?
        @errors << "Step #{index + 1}: sequence is required"
      end

      # Validate attachment_export_mode if present
      if step_data['attachment_export_mode'].present?
        valid_modes = %w[ignore url raw_data]
        unless valid_modes.include?(step_data['attachment_export_mode'])
          @errors << "Step #{index + 1}: invalid attachment_export_mode '#{step_data['attachment_export_mode']}'"
        end
      end
    end

    def create_plan_with_steps(config)
      plan_data = config['plan']

      ActiveRecord::Base.transaction do
        # Find or create the migration plan by name
        plan = MigrationPlan.find_or_create_by!(name: plan_data['name']) do |p|
          p.user = current_user
        end

        # Update plan attributes
        plan.update!(
          description: plan_data['description'],
          user: current_user
        )

        # Create/update steps in sequence order (important for dependencies)
        sorted_steps = plan_data['steps'].sort_by { |s| s['sequence'] }

        sorted_steps.each do |step_data|
          create_or_update_step(plan, step_data)
        end

        # Resolve dependencies after all steps are created/updated
        resolve_dependencies(plan, sorted_steps)

        plan
      end
    end

    def create_or_update_step(plan, step_data)
      # Find or create step by plan and sequence
      step = MigrationStep.find_or_create_by!(
        migration_plan: plan,
        sequence: step_data['sequence']
      )

      # Update step attributes
      step.update!(
        source_model_name: step_data['source_model_name'],
        filter_query: step_data['filter_query'] || '',
        column_overrides: step_data['column_overrides'] || {},
        association_overrides: step_data['association_overrides'] || {},
        attachment_export_mode: step_data['attachment_export_mode'] || 'ignore',
        attachment_fields: step_data['attachment_fields'],
        dependee_attribute_mapping: step_data['dependee_attribute_mapping'] || {}
      )

      # Store in mapping for later dependency resolution
      @step_mapping[step_data['sequence']] = {
        step: step,
        dependee_sequence: step_data['dependee_sequence']
      }

      step
    end

    def resolve_dependencies(plan, sorted_steps)
      @step_mapping.each do |sequence, data|
        step = data[:step]
        dependee_sequence = data[:dependee_sequence]

        next unless dependee_sequence.present?

        # Find the dependee step by sequence
        dependee_data = @step_mapping[dependee_sequence]
        if dependee_data
          step.update!(dependee: dependee_data[:step])
        else
          Rails.logger.warn "Could not resolve dependency for step #{sequence}: dependee sequence #{dependee_sequence} not found"
        end
      end
    end
  end
end