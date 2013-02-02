class Rational
  def self.new_with(coder)
    case coder.type
    when :map
      Rational(coder.map['numerator'], coder.map['denominator'])
    else
      # TODO: I bet there it a better *internal* call for this.
      Rational(coder.scalar)
    end
  end
end

