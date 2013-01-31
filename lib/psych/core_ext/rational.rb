class Rational
  def self.yaml_new(value)
    # TODO: I bet there it a better *internal* call for this.
    Rational(value)
  end
end

