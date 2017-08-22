module Evva
  class Config
    def initialize(hash:)
      @hash = hash.deep_symbolize
      @hash.validate_structure!(CONFIG_STRUCT)

      unless dict_struct = DICTIONARY_STRUCT[@hash[:dictionary][:type]]
        raise ArgumentError.new("unknown dictionary type '#{@hash[:dictionary][:type]}'")
      end

      @hash[:dictionary].validate_structure!(dict_struct)
    end

    def to_h
      @hash
    end

    def dictionary
      @hash[:dictionary]
    end

    def type
      @hash[:type]
    end

    def out_path
      @hash[:out_path]
    end

    private

    CONFIG_STRUCT = {
      type: Hash,
      elements: {
        type: { type: String },
        dictionary: { type: Hash, elements: {
          type: { type: String }
        } },
        out_path: { type: String }
      }
    }

    GOOGLE_SHEET_STRUCT = {
      type: Hash,
      elements: {
        type: { type: String },
        sheet_id: { type: String },
        keys_column: { type: String }
      }
    }

  
    DICTIONARY_STRUCT = {
      "google_sheet" => GOOGLE_SHEET_STRUCT,
    }
  end
end
