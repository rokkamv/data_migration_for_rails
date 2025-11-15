FactoryBot.define do
  factory :migration_record do
    migration_execution { nil }
    migrated_model_name { "MyString" }
    record_identifier { "MyString" }
    action { 1 }
    record_changes { "" }
    error_message { "MyText" }
  end
end
