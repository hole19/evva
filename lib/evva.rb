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
      if file = file_reader.open_file("#{config.out_path}/mixpanel.kt", "w", false)
        events = (generator.events(bundle[:events]))
        file.write(events)
        file.flush
        file.close

        generator.enums(bundle[:enums], config.out_path)
      else
        Logger.error("Could not write to file in #{config.out_path}")
      end
    end

    Evva::Logger.print_summary
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