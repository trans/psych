class Array
  def init_with(coder)
    case coder.type
    when :map
      replace coder.map['internal']
      coder.map['ivars'].each do |k,v|
        instance_variable_set(k,v)
      end
    else
      replace coder.seq
    end
  end
end

