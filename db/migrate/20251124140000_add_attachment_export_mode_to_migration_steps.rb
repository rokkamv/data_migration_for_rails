# frozen_string_literal: true

class AddAttachmentExportModeToMigrationSteps < ActiveRecord::Migration[7.1]
  def change
    # 0 = ignore, 1 = url, 2 = raw_data
    add_column :migration_steps, :attachment_export_mode, :integer, default: 0, null: false
    add_column :migration_steps, :attachment_fields, :text
  end
end
