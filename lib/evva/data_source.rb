module Evva
  class DataSource
    def initialize(keys)
      unless keys.is_a?(Hash)
        raise ArgumentError.new("keys: expected Hash, got #{keys.class}")
      end

      keys.each do |event, v|
        unless v.is_a?(Hash)
          raise ArgumentError.new("keys['#{event}']: expected Hash, got #{v.class}")
        end

        v.each do |key,v|
          unless v.is_a?(String) || v.nil?
            raise ArgumentError.new("keys['#{event}']['#{key}']: expected String, got #{v.class}")
          end
        end
      end

      @keys = Hash[keys.map { |k, v| [k.downcase, v] }]
    end
  end
end
