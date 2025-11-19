module DataMigration
  class ExportsController < ApplicationController
    before_action :set_migration_plan

    def new
      authorize @migration_plan, :execute?
      @filter_params = extract_placeholders_from_plan
    end

    def create
      authorize @migration_plan, :execute?

      # Validate that all required filter parameters are provided
      required_params = extract_placeholders_from_plan

      # Permit the filter_params dynamically based on what's required
      provided_params = if params[:filter_params].present? && required_params.any?
        params.require(:filter_params).permit(*required_params.keys)
      else
        {}
      end

      missing_params = required_params.keys.select do |param|
        provided_params[param].blank?
      end

      if missing_params.any?
        flash[:alert] = "Please provide values for: #{missing_params.join(', ')}"
        @filter_params = required_params
        render :new and return
      end

      execution = MigrationExecution.create!(
        migration_plan: @migration_plan,
        user: current_user,
        execution_type: :export,
        status: :pending,
        filter_params: provided_params.to_h
      )

      ExportJob.perform_later(execution.id)

      redirect_to "/data_migration/migration_executions/#{execution.id}", notice: 'Export started. You will be notified when it completes.'
    end

    private

    def set_migration_plan
      @migration_plan = MigrationPlan.find(params[:migration_plan_id])
    end

    def extract_placeholders_from_plan
      placeholders = {}
      @migration_plan.migration_steps.each do |step|
        next if step.filter_query.blank?

        # Extract placeholders like {{param_name}} from filter query
        step.filter_query.scan(/\{\{(\w+)\}\}/).flatten.each do |param|
          placeholders[param] = nil
        end
      end
      placeholders
    end
  end
end
