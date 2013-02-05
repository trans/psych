class String
  def init_with(coder)
    case coder.type
    when :map
      replace coder.map['str']
      coder.map.each do |k,v|
        next if k == 'str'
        k = "@#{k}" unless k.to_s.start_with?('@')
        instance_variable_set(k,v) 
      end
    else
      replace coder.scalar
    end
  end
end

