module DataMigration
  class MigrationStepsController < ApplicationController
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

      if @migration_step.save
        redirect_to "/data_migration/migration_plans/#{@migration_plan.id}", notice: 'Migration step was successfully created.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @migration_step
    end

    def update
      authorize @migration_step

      if @migration_step.update(migration_step_params)
        redirect_to "/data_migration/migration_plans/#{@migration_plan.id}", notice: 'Migration step was successfully updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @migration_step

      @migration_step.destroy
      redirect_to "/data_migration/migration_plans/#{@migration_plan.id}", notice: 'Migration step was successfully destroyed.'
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
        :model_filters, :association_selections, :polymorphic_associations,
        included_models: [], excluded_models: []
      )
    end
  end
end
