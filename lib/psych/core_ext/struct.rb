class Struct
  def self.new_with(coder)
    value = coder.map
    new(*value.map { |k,v| k.to_sym }).new(*value.map { |k,v| v })
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

