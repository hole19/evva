module Evva
  class Config
    def initialize(hash:)
      @hash = hash.deep_symbolize
      @hash.validate_structure!(CONFIG_STRUCT)

      unless dict_struct = DICTIONARY_STRUCT[@hash[:data_source][:type]]
        raise ArgumentError, "unknown data source type '#{@hash[:data_source][:type]}'"
      end

      @hash[:data_source].validate_structure!(dict_struct)
    end

    def to_h
      @hash
    end

    def data_source
      @hash[:data_source]
    end

    def type
      @hash[:type]
    end

    def out_path
      @hash[:out_path]
    end

    def event_file_name
      @hash[:event_file_name]
    end

    def people_file_name
      @hash[:people_file_name]
    end

    def event_enum_file_name
      @hash[:event_enum_file_name]
    end

    def special_enum_file_name
      @hash[:special_enum_file_name]
    end

    CONFIG_STRUCT = {
      type: Hash,
      elements: {
        type: { type: String },
        data_source: { type: Hash, elements: {
          type: { type: String }
        } },
        out_path: { type: String },
        event_file_name: { type: String },
        event_enum_file_name: { type: String },
        people_file_name: { type: String }
      }
    }.freeze

    GOOGLE_SHEET_STRUCT = {
      type: Hash,
      elements: {
        type: { type: String },
        sheet_id: { type: String }
      }
    }.freeze

    DICTIONARY_STRUCT = {
      'google_sheet' => GOOGLE_SHEET_STRUCT
    }.freeze
  end
end
