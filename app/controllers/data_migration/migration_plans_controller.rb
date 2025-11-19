module DataMigration
  class MigrationPlansController < ApplicationController
    include DataMigration::PunditAuthorization

    before_action :set_migration_plan, only: %i[show edit update destroy]

    def index
      @migration_plans = policy_scope(MigrationPlan).ordered_by_name
    end

    def show
      authorize @migration_plan
    end

    def new
      @migration_plan = MigrationPlan.new
      authorize @migration_plan
    end

    def create
      @migration_plan = MigrationPlan.new(migration_plan_params)
      authorize @migration_plan

      if @migration_plan.save
        redirect_to "/data_migration/migration_plans/#{@migration_plan.id}", notice: 'Migration plan was successfully created.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @migration_plan
    end

    def update
      authorize @migration_plan

      if @migration_plan.update(migration_plan_params)
        redirect_to "/data_migration/migration_plans/#{@migration_plan.id}", notice: 'Migration plan was successfully updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @migration_plan

      if @migration_plan.destroy
        redirect_to "/data_migration/migration_plans", notice: 'Migration plan was successfully destroyed.'
      else
        redirect_to "/data_migration/migration_plans/#{@migration_plan.id}", alert: 'Cannot delete migration plan with existing executions.'
      end
    end

    private

    def set_migration_plan
      @migration_plan = MigrationPlan.find(params[:id])
    end

    def migration_plan_params
      params.require(:migration_plan).permit(:name, :description, settings: [])
    end
  end
end
