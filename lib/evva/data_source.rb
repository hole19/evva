module Evva
  class DataSource
    def initialize(keys)
      unless keys.is_a?(Hash)
        raise ArgumentError, "keys: expected Hash, got #{keys.class}"
      end

      keys.each do |property, v|
        unless v.is_a?(Hash)
          raise ArgumentError, "keys['#{property}']: expected Hash, got #{v.class}"
        end

        v.each do |key, v|
          unless v.is_a?(String) || v.nil?
            raise ArgumentError, "keys['#{property}']['#{key}']: expected String, got #{v.class}"
          end
        end
      end

      @keys = Hash[keys.map { |k, v| [k.downcase, v] }]
    end
  end
end
