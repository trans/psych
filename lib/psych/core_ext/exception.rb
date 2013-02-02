class Exception
  def self.new_with(coder)
    case coder.type
    when :map
      exception(coder.map['message'])
    else
      exception(coder.scalar)
    end
  end
end

