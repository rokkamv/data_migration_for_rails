# frozen_string_literal: true

module DataMigration
  module ApplicationHelper
    def execution_status_color(status)
      case status.to_sym
      when :pending
        'secondary'
      when :running
        'primary'
      when :completed
        'success'
      when :failed
        'danger'
      else
        'secondary'
      end
    end

    def execution_type_icon(type)
      type.to_sym == :export ? '📤' : '📥'
    end
  end
end
