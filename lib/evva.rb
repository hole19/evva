require "optparse"
require "yaml"

require "evva/logger"
require "evva/google_sheet"
require "evva/config"
require "evva/file_reader"
require "evva/analytics_event"
require "evva/analytics_enum"
require "evva/analytics_property"
require "evva/object_extension"
require "evva/version"
require "evva/kotlin_generator"
require "evva/swift_generator"

module Evva
  extend self
  def run(options)
    file_reader = Evva::FileReader.new
    options = command_line_options(options)
    unless config_file = file_reader.open_file("evva_config.yml", "r", true)
      Logger.error("Could not open evva_config.yml")
      return
    end

    config = Evva::Config.new(hash: YAML.safe_load(config_file))
    bundle = analytics_data(config: config.data_source)
    filter_destinations!(bundle, config.exclude_destinations)
    filter_platforms!(bundle, config.type)
    case config.type.downcase
    when "android"
      generator = Evva::KotlinGenerator.new(config.package_name)
      evva_write(bundle, generator, config, "kt")
    when "ios"
      generator = Evva::SwiftGenerator.new(swift_public: config.swift_public?)
      evva_write(bundle, generator, config, "swift")
    end
    Evva::Logger.print_summary
  end

  def evva_write(bundle, generator, configuration, extension)
    path = "#{configuration.out_path}/#{configuration.event_file_name}.#{extension}"
    write_to_file(path, generator.events(bundle[:events], configuration.event_file_name, configuration.event_enum_file_name, configuration.destinations_file_name))

    unless configuration.type.downcase == "ios"
      path = "#{configuration.out_path}/#{configuration.event_enum_file_name}.#{extension}"
      write_to_file(path, generator.event_enum(bundle[:events], configuration.event_enum_file_name))
    end

    path = "#{configuration.out_path}/#{configuration.people_file_name}.#{extension}"
    write_to_file(path, generator.people_properties(bundle[:people], configuration.people_file_name, configuration.people_enum_file_name, configuration.destinations_file_name))

    unless configuration.type.downcase == "ios"
      path = "#{configuration.out_path}/#{configuration.people_enum_file_name}.#{extension}"
      write_to_file(path, generator.people_properties_enum(bundle[:people], configuration.people_enum_file_name))
    end

    path = "#{configuration.out_path}/#{configuration.special_enum_file_name}.#{extension}"
    write_to_file(path, generator.special_property_enums(bundle[:enums]))

    path = "#{configuration.out_path}/#{configuration.destinations_file_name}.#{extension}"
    write_to_file(path, generator.destinations(bundle[:destinations], configuration.destinations_file_name))
  end

  def analytics_data(config:)
    source =
      case config[:type]
      when "google_sheet"
        Evva::GoogleSheet.new(config[:events_url], config[:people_properties_url], config[:enum_classes_url])
      end
    events_bundle = {}
    events_bundle[:events] = source.events
    events_bundle[:people] = source.people_properties
    events_bundle[:enums] = source.enum_classes
    events_bundle[:destinations] = source.destinations
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

  def filter_destinations!(bundle, excluded)
    return if excluded.empty?

    bundle[:destinations].reject! { |d| excluded.include?(d) }
    bundle[:events].each { |e| e.destinations.reject! { |d| excluded.include?(d) } }
    bundle[:people].each { |p| p.destinations.reject! { |d| excluded.include?(d) } }
  end

  def filter_platforms!(bundle, platform)
    platform = platform.to_s.downcase
    return unless Evva::AnalyticsEvent::PLATFORMS.include?(platform)

    kept, filtered = bundle[:events].partition { |event| event.supports_platform?(platform) }
    return if filtered.empty?

    bundle[:events] = kept
    Logger.info("filtered #{filtered.size} events (#{filtered.map(&:event_name).join(', ')})")

    # Only what the dropped events were keeping alive. An enum that had no
    # reference before this run keeps its place on purpose: pruning those would
    # change the output of sheets that have no Platform column at all.
    orphaned = types_referenced_by(filtered) - types_referenced_by(kept, bundle[:people])
    pruned, remaining = bundle[:enums].partition { |enum| orphaned.include?(enum.enum_name) }
    return if pruned.empty?

    bundle[:enums] = remaining
    Logger.info("pruned #{pruned.size} enums (#{pruned.map(&:enum_name).join(', ')})")
  end

  # Every property type these events and people properties name, with the
  # optional marker stripped. The caller compares against real enum names, so
  # this never has to decide whether a type is an enum. People properties are
  # never platform filtered but still hold references, so an enum kept alive only
  # by one must survive.
  def types_referenced_by(events, people = [])
    types = events.flat_map { |event| event.properties.values } + people.map(&:type)
    types.map { |type| type.to_s.chomp("?") }
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
