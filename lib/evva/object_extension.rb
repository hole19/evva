Object.class_eval do
  def deep_symbolize
    case self
    when Array
      map(&:deep_symbolize)
    when Hash
      each_with_object({}) { |(k, v), memo| memo[k.to_sym] = v.deep_symbolize; }
    else
      self
    end
  end

  def validate_structure!(structure, error_prefix = [])
    return if nil? && structure[:optional]

    prepend_error = error_prefix.empty? ? "" : (["self"] + error_prefix + [": "]).join

    unless is_a? structure[:type]
      raise ArgumentError, "#{prepend_error}Expected #{structure[:type]}, got #{self.class}"
    end

    return unless structure[:elements]

    case self
    when Array
      each_with_index do |e, i|
        e.validate_structure!(structure[:elements], error_prefix + ["[#{i}]"])
      end
    when Hash
      mandatory_keys = structure[:elements].map { |k, s| k unless s[:optional] }.compact

      unless (missing = mandatory_keys - keys).empty?
        raise ArgumentError, "#{prepend_error}Missing keys: #{missing.join(', ')}"
      end

      structure[:elements].each do |key, structure|
        self[key].validate_structure!(structure, error_prefix + ["[:#{key}]"])
      end
    end
  end
end
