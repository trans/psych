class Struct
  ###
  # Struct::Factory is used to construct annonymous Struct classes. Struct class
  # itself can't be used, b/c then it would need two different means of 
  # construction/instantiation.
  module Factory
    def self.new_with(coder)
      value = coder.map
      Struct.new(*value.map { |k,v| k.to_sym }).new(*value.map { |k,v| v })
    end
  end

  def init_with(coder)
    coder.map.each do |m, v|
      if members.include?(m.to_sym)
        send("#{m}=", v)
      else
        iv = m.to_s.start_with?('@') ? m : "@#{m}"
        instance_variable_set(iv, v)
      end
    end
  end
end

