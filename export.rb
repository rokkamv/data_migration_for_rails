module Export
  require 'csv'
  require 'json'
  require_relative 'helper'
  include Helper

  def get_headers_export(model_name, model_info)
    query_string = "p #{model_name}.column_names"
    list_string = run_app_query(query_string)
    headers = JSON.parse(list_string)
    if model_info.keys.include?('id_based_association')
      model_info['id_based_association'].each do |k, v|
        headers.delete(k)
        v.each { |method| headers.push(method) }
      end
    end
    headers
  end

  def rows_data(model_name, model_info, partner_code)
    assocn_data_subquery = ''
    if model_info.keys.include?('id_based_association')
      model_info['id_based_association'].each do |_k, v|
        v.each { |m| assocn_data_subquery += "tmp['#{m}'] = record#{m}\n  " }
      end
    end
    query_string = <<~HEREDOC
      #{model_info['records_filter'].gsub('{partner_code}', partner_code)}
      src_attrs = []
      src_records.each do |record|
        tmp = record.attributes
        #{assocn_data_subquery}
        src_attrs << tmp
      end
      puts src_attrs.to_json
    HEREDOC
    run_app_query(query_string)
  end

  def export
    failed_attempts = 0
    partner_code = ''
    loop do
      puts 'Please enter the unique Partner Code:'
      partner_code = gets.chomp
      partner_validation = validate_partner(partner_code)
      case partner_validation
      when 'false'
        puts "Partner with the code '#{partner_code}' not found! Incorrect attempts(Max. 5): #{failed_attempts += 1}"
      when 'true'
        puts "Validation Success! Partner with the code '#{partner_code}' exists."
        break
      end
      return 'main_menu' if failed_attempts == 5
    end
    direct_models_info = metadata.reject { |k, _| k if k.include?('.') }
    dest_dir = File.join(File.expand_path(__dir__), 'export_csv_files', partner_code.to_s, "#{DateTime.now.strftime('%Y%m%d_%H%M%S%z')}_export")
    puts `mkdir -p #{dest_dir}`
    direct_models_info.each do |model_name, model_info|
      puts "\nGenerating Export CSV file for the model '#{model_name}'..."
      export_filename = File.join(dest_dir, "#{model_name}_export.csv")
      export_file = File.open(export_filename, 'w+')
      csv = CSV.generate do |rows|
        headers = get_headers_export(model_name, model_info)
        rows << headers
        records = JSON.parse(rows_data(model_name, model_info, partner_code))
        records.each do |record|
          row = headers.map { |header| record[header] }
          rows << row
        end
      end
      export_file.puts csv
      export_file.close
      puts "Export file for the model '#{model_name}' saved at '#{export_filename}'."
    end
    puts "\nCompressing export folder located at #{dest_dir}"
    puts `tar -zcvf #{dest_dir}.tar.gz #{dest_dir}`
    if File.exist?("#{dest_dir}.tar.gz")
      puts "Compressed file of export files directory is available at #{dest_dir}.tar.gz !"
      puts `rm -rf #{dest_dir}`
    else
      puts "Compressed file #{dest_dir}.tar.gz not present. Some error has occurred!"
    end
    'main_menu'
  end
end
