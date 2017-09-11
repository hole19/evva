require 'optparse'
require 'yaml'

require 'evva/logger'
require 'evva/google_sheet'
require 'evva/config'
require 'evva/file_reader'
require 'evva/data_source'
require 'evva/mixpanel_event'
require 'evva/mixpanel_enum'
require 'evva/mixpanel_property'
require 'evva/object_extension'
require 'evva/version'
require 'evva/android_generator'
require 'evva/swift_generator'
require 'evva/ega_calculator'
require 'evva/usga_calculator'
require 'evva/congu_calculator'

module Evva
  extend self
  def run(options)
    file_reader = Evva::FileReader.new()
    options = command_line_options(options)
    if config_file = file_reader.open_file('generic.yml', 'r', true)
      config       = Evva::Config.new(hash: YAML::load(config_file))
      bundle       = analytics_data(config: config.data_source)
      type         = config.type
    else
      Logger.error("Could not open #{file_name}!")
      return nil
    end

    if type.eql? "Android"
      generator = Evva::AndroidGenerator.new()
      evva_write(bundle, generator, config, "kt")
    end

    if type.eql? "iOS"
      generator = Evva::SwiftGenerator.new()
      evva_write(bundle, generator, config, "swift")
    end
    Evva::Logger.print_summary
  end

  def evva_write(bundle, generator, configuration, file_extension)
    file_reader = Evva::FileReader.new()
    if file = file_reader.open_file(
      "#{configuration.out_path}/#{configuration.event_file_name}.#{file_extension}", "w", false)
      events = (generator.events(bundle[:events]))
      file_reader.write_to_file(file, events)
    else
      Logger.error("Could not write to file in #{configuration.out_path}")
    end
    
    event_enum = generator.event_enum(bundle[:events])
    event_enum_file = file_reader.open_file(
      "#{configuration.out_path}/#{configuration.event_enum_file_name}.#{file_extension}", "w", false)
    
    file_reader.write_to_file(event_enum_file, event_enum)

    people = (generator.people_properties(bundle[:people]))
    people_file = file_reader.open_file(
      "#{configuration.out_path}/#{configuration.people_file_name}.#{file_extension}", "w", false)
    
    file_reader.write_to_file(people_file, people)

    bundle[:enums].each do |enum|
      enum_file = file_reader.open_file(
        "#{configuration.out_path}/#{enum.enum_name}.#{file_extension}", "w", false)
      file_reader.write_to_file(enum_file, generator.special_property_enum(enum))
    end
  end

  def analytics_data(config:)
    source =
    case config[:type]
    when "google_sheet"
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

      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end

      opts.on_tail("-v", "--version", "Show version") do
        puts Evva::VERSION
        exit
      end
    end
    opts_parser.parse!(options)

    opts_hash
  end
end