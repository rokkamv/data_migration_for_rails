module Helper
  require 'yaml'

  def metadata
    @metadata ||= YAML.load_file("#{File.expand_path(__dir__)}/metadata.yml")
  end

  def config
    @config ||= YAML.load_file("#{File.expand_path(__dir__)}/config.yml")
  end

  def run_app_query(query_string)
    `#{config['bin_rails_path']} runner "#{query_string}"`.chomp.gsub('\u0026', '&')
  end

  def validate_partner(partner_code)
    puts 'Please wait validating the Partner...'
    query_string = "p Partner.where(partner_code: '#{partner_code}').count.positive?"
    run_app_query(query_string)
  end

end
