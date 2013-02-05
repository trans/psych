class Symbol
  def self.new_with(coder)
    str = coder.scalar.to_s
    if str.start_with?(':')
      str[1..-1].to_sym
    else
      str.to_sym
    end
  end
end

