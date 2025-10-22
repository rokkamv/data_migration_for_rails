require 'date'
require 'logger'
require_relative 'export'
include Export
require_relative 'import'
include Import

logger = Logger.new("#{File.expand_path(__dir__)}/logs/#{DateTime.now.strftime('%Y%m%d')}_export.log")

def validate_action_input(optns, user_input, input_map)
  if user_input == optns
    'exit'
  elsif (1..optns).include?(user_input.to_i)
    input_map[user_input]
  else
    puts 'Invalid option selected!'
    'invalid_input'
  end

end

def main_menu
  form_str = <<~HEREDOC


    |MAIN MENU|

    (1) Export
    (2) Import
    (3) Exit
    Please enter an integer associated with option you want to select:
  HEREDOC
  input_method_map = { 1 => 'export_menu', 2 => 'import_menu' }
  puts form_str
  main_list_inp = gets.chomp
  validation = validate_action_input(3, main_list_inp.to_i, input_method_map)
  case validation
  when 'exit'
    frontend(0)
  else
    validation
  end
end

def export_menu
  form_str = <<~HEREDOC


    |EXPORT MENU|

    (1) Enter Partner Code
    (2) Main Menu
    (3) Exit
    Please enter an integer associated with option you want to select:
  HEREDOC
  input_method_map = { 1 => 'export', 2 => 'main_menu' }
  puts form_str
  export_list_inp = gets.chomp
  validation = validate_action_input(3, export_list_inp.to_i, input_method_map)
  case validation
  when 'exit'
    frontend(0)
  else
    validation
  end
end

def import_menu
  form_str = <<~HEREDOC


    |IMPORT MENU|

    (1) Enter Partner Code
    (2) Main Menu
    (3) Exit
    Please enter an integer associated with option you want to select:
  HEREDOC
  input_method_map = { 1 => 'import', 2 => 'main_menu' }
  puts form_str
  import_list_inp = gets.chomp
  validation = validate_action_input(3, import_list_inp.to_i, input_method_map)
  case validation
  when 'exit'
    frontend(0)
  else
    validation
  end
end

def frontend(step = 'main_menu')
  case step
  when 0
    puts '--------- Exiting the tool ---------'
    exit
  else
    resp = send(step)
    resp = send(step) while resp.to_s == 'invalid_input'
    frontend(resp) unless resp.nil?
  end
end

puts '--------- API Service Configuration Migration tool ---------'
puts "\nIMPORTANT!!! Please ensure the config.yml and metadata.yml files are configured with correct values.\n"

frontend
