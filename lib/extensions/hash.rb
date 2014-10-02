class Hash
  unless Hash.instance_methods.include?(:stringify_keys!)
    def stringify_keys!
      keys.each do |key|
        unless key.kind_of?(String)
          self[key.to_s] = delete(key)
        end
      end

      self
    end
  end
end
