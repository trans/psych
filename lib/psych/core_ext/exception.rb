class Exception
  def self.new_with(coder)
    case coder.type
    when :map
      err = exception(coder.map['message'])
      coder.map.each do |k,v|
        next if k == 'message'
        iv = k.to_s.start_with?('@') ? k : "@#{k}"
        err.instance_variable_set(iv, v)
      end
      err
    else
      exception(coder.scalar)
    end
  end
end

