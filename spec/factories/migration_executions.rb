FactoryBot.define do
  factory :migration_execution do
    migration_plan { nil }
    user { nil }
    execution_type { 1 }
    status { 1 }
    started_at { "2025-11-06 03:27:02" }
    completed_at { "2025-11-06 03:27:02" }
    file_path { "MyString" }
    stats { "" }
    error_log { "MyText" }
  end
end
