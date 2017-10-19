require 'optparse'
require 'yaml'

require 'evva/logger'
require 'evva/google_sheet'
require 'evva/config'
require 'evva/file_reader'
require 'evva/data_source'
require 'evva/mixpanel_event'
require 'evva/mixpanel_enum'
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
      generator = Evva::AndroidGenerator.new
      evva_write(bundle, generator, config, 'kt')
    when 'ios'
      generator = Evva::SwiftGenerator.new
      evva_write(bundle, generator, config, 'swift')
    end
    Evva::Logger.print_summary
  end

  def evva_write(bundle, generator, configuration, extension)
    path = "#{configuration.out_path}/#{configuration.event_file_name}.#{extension}"
    write_to_file(path, generator.events(bundle[:events]))

    path = "#{configuration.out_path}/#{configuration.event_enum_file_name}.#{extension}"
    write_to_file(path, generator.event_enum(bundle[:events]))

    path = "#{configuration.out_path}/#{configuration.people_file_name}.#{extension}"
    write_to_file(path, generator.people_properties(bundle[:people]))

    bundle[:enums].each do |enum|
      path = "#{configuration.out_path}/#{enum.enum_name}.#{extension}"
      write_to_file(path, generator.special_property_enum(enum))
    end
  end

  def analytics_data(config:)
    source =
      case config[:type]
      when 'google_sheet'
        Evva::GoogleSheet.new(config[:sheet_id])
      end
    events_bundle = {}
    events_bundle[:events] = source.events
    events_bundle[:people] = source.people_properties
    events_bundle[:enums] = source.enum_classes
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
