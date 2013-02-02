class Range
  # Deserialize YAML representation into Range.
  def self.new_with(coder)
    case coder.type
    when :scalar
      b, x, e = coder.scalar.split(/([.]{2,3})/, 2)
      b = coder.token(b)
      e = coder.token(e)
      Range.new(b, e, x == '...')
    when :seq
      new(*coder.seq)
    when :map
      new(*coder.map.values_at('begin', 'end', 'excl'))
    end
  end
end

