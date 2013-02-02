class Symbol
  def self.new_with(coder)
    str = coder.scalar.to_s
    if str.start_with?(':')
      str[1..-1].to_str
    else
      str.to_str
    end
  end
end

