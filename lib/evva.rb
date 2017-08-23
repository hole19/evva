require 'optparse'
require 'yaml'
require 'fileutils'

require 'evva/logger'
require 'evva/google_sheet'
require 'evva/config'
require 'evva/dictionary'
require 'evva/mixpanel_event'
require 'evva/mixpanel_enum'
require 'evva/object_extension'
require 'evva/version'
require 'evva/event_generator'
require 'evva/enum_generator'

module Evva
  extend self
  def run(options)
    options = command_line_options(options)
    if config_file = open_file('generic.yml', 'r', true)
      config       = Evva::Config.new(hash: YAML::load(config_file))
      bundle       = analytics_data(config: config.dictionary)
    end
    event_generator = Evva::EventGenerator.new()
    event_generator.build(bundle[:events], config.type, config.out_path)
    enum_generator = Evva::EnumGenerator.new()
    enum_generator.build(bundle[:enums], config.type, config.out_path)
    Evva::Logger.print_summary
  end

  def analytics_data(config:)
    source =
    case config[:type]
    when "google_sheet"
      Evva::GoogleSheet.new(config[:sheet_id], config[:keys_column])
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

  def open_file(file_name, method, should_exist)
    if !File.file?(File.expand_path(file_name))
      if should_exist
        Logger.error("File #{file_name} not found!")
        return nil
      else
        FileUtils.mkdir_p(File.dirname(file_name))
      end
    end

    File.open(File.expand_path(file_name), method)
  end

end