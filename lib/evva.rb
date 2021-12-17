require 'optparse'
require 'yaml'

require 'evva/logger'
require 'evva/google_sheet'
require 'evva/config'
require 'evva/file_reader'
require 'evva/analytics_event'
require 'evva/analytics_enum'
require 'evva/analytics_property'
require 'evva/object_extension'
require 'evva/version'
require 'evva/android_generator'
require 'evva/swift_generator'

module Evva
  extend self
  def run(options)
    file_reader = Evva::FileReader.new
    options = command_line_options(options)
    unless config_file = file_reader.open_file('evva_config.yml', 'r', true)
      Logger.error("Could not open evva_config.yml")
      return
    end

    config = Evva::Config.new(hash: YAML.safe_load(config_file))
    bundle = analytics_data(config: config.data_source)
    case config.type.downcase
    when 'android'
      generator = Evva::AndroidGenerator.new(config.package_name)
      evva_write(bundle, generator, config, 'kt')
    when 'ios'
      generator = Evva::SwiftGenerator.new
      evva_write(bundle, generator, config, 'swift')
    end
    Evva::Logger.print_summary
  end

  def evva_write(bundle, generator, configuration, extension)
    path = "#{configuration.out_path}/#{configuration.event_file_name}.#{extension}"
    write_to_file(path, generator.events(bundle[:events], configuration.event_file_name))

    unless configuration.type.downcase == 'ios'
      path = "#{configuration.out_path}/#{configuration.event_enum_file_name}.#{extension}"
      write_to_file(path, generator.event_enum(bundle[:events], configuration.event_enum_file_name))
    end

    path = "#{configuration.out_path}/#{configuration.people_file_name}.#{extension}"
    write_to_file(path, generator.people_properties(bundle[:people], configuration.people_file_name))

    path = "#{configuration.out_path}/#{configuration.special_enum_file_name}.#{extension}"
    write_to_file(path, generator.special_property_enums(bundle[:enums]))

    if configuration.type.downcase == 'ios'
      path = "#{configuration.out_path}/#{configuration.platforms_file_name}.#{extension}"
      write_to_file(path, generator.platforms(bundle[:platforms], configuration.platforms_file_name))
    end
  end

  def analytics_data(config:)
    source =
      case config[:type]
      when 'google_sheet'
        Evva::GoogleSheet.new(config[:events_url], config[:people_properties_url], config[:enum_classes_url])
      end
    events_bundle = {}
    events_bundle[:events] = source.events
    events_bundle[:people] = source.people_properties
    events_bundle[:enums] = source.enum_classes
    events_bundle[:platforms] = source.platforms
    events_bundle
  end

  def command_line_options(options)
    opts_hash = {}

    opts_parser = OptionParser.new do |opts|
      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end

      opts.on_tail('-v', '--version', 'Show version') do
        puts Evva::VERSION
        exit
      end
    end
    opts_parser.parse!(options)

    opts_hash
  end

  def write_to_file(path, data)
    file_reader = Evva::FileReader.new
    if file = file_reader.open_file(path, "w", false)
      file_reader.write_to_file(file, data)
    else
      Logger.error("Could not write to file in #{path}")
    end
  end
end
