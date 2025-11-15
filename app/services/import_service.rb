module Import
  require 'csv'
  require 'json'
  require_relative 'helper'
  include Helper

  def get_headers_import(model_name)
    query_string = "p #{model_name}.column_names"
    list_string = run_app_query(query_string)
    JSON.parse(list_string)
  end

  def update_id_assocn_attrs(model_name, model_info, import_file_row)
    model_info['id_based_association']&.each do |k, v|
      attr_name = k.split('|')&.first&.strip
      attr_model = k.split('|')&.last&.strip
      next if model_info['ignore_on_update']&.include?(attr_name)

      find_by_params = ''
      v.each { |method| find_by_params += "#{method.split('.').last}: #{import_file_row[method]}," }
      attr_value = run_app_query("puts #{attr_model}.find_by(#{find_by_params.chop})&.id")
      import_file_row[attr_name] = attr_value&.to_i
    end
    import_file_row
  end

  def find_record(model_name, model_info, updated_import_file_row)
    find_by_params = ''
    model_info['uniq_record_id_cols'].each { |col_name| find_by_params += "#{col_name}: '#{updated_import_file_row[col_name]}'," }
    query_string = <<~HEREDOC
      record = #{model_name}.find_by(#{find_by_params.chop})
      if record
        record_resp = record.attributes
        record_resp[:IMPORT_ACTION_STATUS] = 'record_found'
      else
        record_resp = { IMPORT_ACTION_STATUS: 'record_not_found'}
      end
      puts record_resp.to_json
    HEREDOC
    run_app_query(query_string)
  end

  def update_record(model_name, model_info, existing_record, updated_import_file_row, headers)
    existing_record_updated_at = DateTime.parse(existing_record['updated_at'])
    updated_import_file_row_updated_at = DateTime.parse(updated_import_file_row['updated_at'])
    record_resp = {}
    if existing_record_updated_at < updated_import_file_row_updated_at || model_name == 'Partner'
      ignore_params = %w[id created_at updated_at] + model_info['uniq_record_id_cols'] + model_info['ignore_on_update'].to_a
      ignore_params.flatten!
      ignore_params.compact!
      update_params = ''
      updated_import_file_row.each do |k, v|
        update_params += "#{k}: '#{v}'," if !ignore_params.include?(k) && headers.include?(k)
      end
      query_string = <<~HEREDOC
        record = #{model_name}.find(#{existing_record['id']})
        record.update(#{update_params.chop})
        record.reload
        puts record.attributes.to_json
      HEREDOC
      updated_record = JSON.parse(run_app_query(query_string))
      existing_record.each { |k, v| record_resp[k] = "#{v} --->>> #{updated_record[k]}" }
      record_resp['IMPORT_ACTION_STATUS'] = 'UPDATED'
    else
      existing_record.each { |k, v| record_resp[k] = v }
      record_resp['IMPORT_ACTION_STATUS'] = 'NOT_MODIFIED'
    end
    record_resp
  end

  def create_record(model_name, model_info, updated_import_file_row, headers)
    model_info['id_based_association']&.each do |k, v|
      attr_name = k.split('|')&.first&.strip
      attr_model = k.split('|')&.last&.strip
      if attr_model == 'Attachment' && updated_import_file_row[v[0]]&.include?('http')
        attr_value = run_app_query("Attachment.create(file: URI.parse(#{updated_import_file_row[v[0]]}).open)&.id")
        updated_import_file_row[attr_name] = attr_value&.to_i
      else
        updated_import_file_row[attr_name] = nil
      end
    end
    ignore_params = %w[id created_at updated_at]
    create_params = ''
    updated_import_file_row.each do |k, v|
      create_params += "#{k}: '#{v}'," if !ignore_params.include?(k) && headers.include?(k)
    end
    query_string = <<~HEREDOC
      record = #{model_name}.create(#{create_params.chop})
      if record.class == 'Admin'
        record.update(password: 'Admin123')
      end
      puts record.attributes.to_json
    HEREDOC
    created_record = JSON.parse(run_app_query(query_string))
    created_record['IMPORT_ACTION_STATUS'] = 'CREATED'
    created_record
  end

  def process_import_file_row(model_name, model_info, import_file_row, headers)
    updated_import_file_row = update_id_assocn_attrs(model_name, model_info, import_file_row)
    find_record_resp = JSON.parse(find_record(model_name, model_info, updated_import_file_row))
    case find_record_resp['IMPORT_ACTION_STATUS']
    when 'record_found'
      resp = update_record(model_name, model_info, find_record_resp, updated_import_file_row, headers)
    when 'record_not_found'
      resp = create_record(model_name, model_info, updated_import_file_row, headers)
    end
    resp
  end

  def import
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
    src_partner_dir = File.join(File.expand_path(__dir__), 'import_csv_files', partner_code.to_s)
    puts `mkdir -p #{src_partner_dir}`
    puts "\nPlease place the Compressed file (.tar.gz) into the #{src_partner_dir} directory!"
    failed_attempts = 0
    src_file = ''
    import_filename = ''
    loop do
      puts 'Please enter the .tar.gz file name(Example- 20230223_142641+0530_export.tar.gz):'
      import_filename = gets.chomp
      src_file = File.join(src_partner_dir, import_filename)
      import_file_validation = File.exist?(src_file)
      case import_file_validation
      when false
        puts "Compressed file '#{src_file}' not found! Incorrect attempts(Max. 5): #{failed_attempts += 1}"
      when true
        puts "Compressed file '#{src_file}' will be processed for the Partner with the code '#{partner_code}'."
        break
      end
      return 'main_menu' if failed_attempts == 5
    end
    src_dir = src_file.gsub('.tar.gz', '')
    puts `mkdir -p #{src_dir}`
    puts `tar -zxvf #{src_file} -C #{src_dir} --transform='s:.*/::'`
    dest_dir = File.join(File.expand_path(__dir__), 'import_csv_files', partner_code.to_s, import_filename.gsub('_export.tar.gz', '_import'))
    puts `mkdir -p #{dest_dir}`
    direct_models_info = metadata.reject { |k, _| k if k.include?('.') }
    direct_models_info.each do |model_name, model_info|
      model_file = "#{model_name}_export.csv"
      puts "\nProcessing CSV file '#{model_file}' for the model '#{model_name}'..."
      src_filename = File.join(src_dir, model_file)
      journal_filename = File.join(dest_dir, "#{model_name}_journal.csv")
      journal_file = File.open(journal_filename, 'w+')
      csv = CSV.generate do |journal_rows|
        headers = ['IMPORT_ACTION_STATUS'] + get_headers_import(model_name)
        journal_rows << headers
        CSV.foreach(src_filename, headers: true) do |row|
          process_resp = process_import_file_row(model_name, model_info, row, headers)
          journal_row = headers.map { |header| process_resp[header] }
          journal_rows << journal_row
        end
      end
      journal_file.puts csv
      journal_file.close
      puts "Import file journal for the model '#{model_name}' saved at '#{journal_filename}'."
    end
    puts "\nCompressing import journal folder located at #{dest_dir}"
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
