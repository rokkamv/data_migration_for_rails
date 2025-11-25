# frozen_string_literal: true

module DataMigration
  class MigrationStepsController < ApplicationController
    include DataMigration::PunditAuthorization

    before_action :set_migration_plan
    before_action :set_migration_step, only: %i[show edit update destroy]

    def index
      @migration_steps = policy_scope(MigrationStep).where(migration_plan_id: params[:migration_plan_id]).order(:sequence)
    end

    def show
      authorize @migration_step
    end

    def new
      @migration_step = @migration_plan.migration_steps.new
      authorize @migration_step
    end

    def create
      @migration_step = @migration_plan.migration_steps.new(migration_step_params)
      authorize @migration_step

      # Validate JSON fields before saving
      validation_errors = validate_json_fields(@migration_step)
      if validation_errors.any?
        validation_errors.each { |error| @migration_step.errors.add(:base, error) }
        render :new, status: :unprocessable_entity
        return
      end

      if @migration_step.save
        redirect_to "/data_migration/migration_plans/#{@migration_plan.id}",
                    notice: 'Migration step was successfully created.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @migration_step
    end

    def update
      authorize @migration_step

      # Assign attributes first
      @migration_step.assign_attributes(migration_step_params)

      # Validate JSON fields before saving
      validation_errors = validate_json_fields(@migration_step)
      if validation_errors.any?
        validation_errors.each { |error| @migration_step.errors.add(:base, error) }
        render :edit, status: :unprocessable_entity
        return
      end

      if @migration_step.save
        redirect_to "/data_migration/migration_plans/#{@migration_plan.id}",
                    notice: 'Migration step was successfully updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @migration_step

      @migration_step.destroy
      redirect_to "/data_migration/migration_plans/#{@migration_plan.id}",
                  notice: 'Migration step was successfully destroyed.'
    end

    private

    def set_migration_plan
      @migration_plan = MigrationPlan.find(params[:migration_plan_id])
    end

    def set_migration_step
      @migration_step = @migration_plan.migration_steps.find(params[:id])
    end

    def migration_step_params
      params.require(:migration_step).permit(
        :source_model_name, :sequence, :filter_query, :dependee_id, :migration_plan_id,
        :dependee_attribute_mapping, :column_overrides, :association_overrides,
        :attachment_export_mode, :attachment_fields
      )
    end

    def validate_json_fields(step)
      errors = []

      # Validate column_overrides
      if step.column_overrides.present?
        begin
          parsed = step.column_overrides.is_a?(String) ? JSON.parse(step.column_overrides) : step.column_overrides
          errors << 'Column Overrides must be a JSON object/hash' unless parsed.is_a?(Hash)
        rescue JSON::ParserError
          errors << 'Column Overrides contains invalid JSON'
        end
      end

      # Validate association_overrides
      if step.association_overrides.present?
        begin
          parsed = step.association_overrides.is_a?(String) ? JSON.parse(step.association_overrides) : step.association_overrides
          if parsed.is_a?(Hash)
            # Validate structure: each value should be a hash with proper keys
            parsed.each do |key, value|
              unless value.is_a?(Hash)
                errors << "Association Overrides: '#{key}' must be a hash"
                next
              end

              # Check for polymorphic associations
              if value['polymorphic'] == true
                # Polymorphic requires type_column and lookup_attributes hash
                if value['type_column'].blank?
                  errors << "Association Overrides: '#{key}' (polymorphic) must have a 'type_column' key"
                end

                if value['lookup_attributes'].blank?
                  errors << "Association Overrides: '#{key}' (polymorphic) must have 'lookup_attributes' key"
                elsif !value['lookup_attributes'].is_a?(Hash)
                  errors << "Association Overrides: '#{key}' (polymorphic) 'lookup_attributes' must be a hash with model types as keys"
                end
              else
                # Non-polymorphic requires model and lookup_attributes
                errors << "Association Overrides: '#{key}' must have a 'model' key" if value['model'].blank?

                if value['lookup_attributes'].blank?
                  errors << "Association Overrides: '#{key}' must have 'lookup_attributes' key"
                elsif !value['lookup_attributes'].is_a?(Array)
                  errors << "Association Overrides: '#{key}' 'lookup_attributes' must be an array"
                end
              end
            end
          else
            errors << 'Association Overrides must be a JSON object/hash'
          end
        rescue JSON::ParserError
          errors << 'Association Overrides contains invalid JSON'
        end
      end

      # Validate dependee_attribute_mapping
      if step.dependee_attribute_mapping.present?
        begin
          parsed = step.dependee_attribute_mapping.is_a?(String) ? JSON.parse(step.dependee_attribute_mapping) : step.dependee_attribute_mapping
          errors << 'Dependee Attribute Mapping must be a JSON object/hash' unless parsed.is_a?(Hash)
        rescue JSON::ParserError
          errors << 'Dependee Attribute Mapping contains invalid JSON'
        end
      end

      errors
    end
  end
end
