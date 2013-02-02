class String
  def init_with(coder)
    # TODO: It would be nice to have a more uniform format for handling `!ruby/`
    #       objects. e.g. use `:@key => 'value'` for all value entries. Perhaps
    #       they should even map to a different class that acts like a factory?
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

