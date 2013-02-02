class Complex
  def self.new_with(coder)
    case coder.type
    when :map
      Complex(coder.map['real'], coder.map['image'])
    else
      # TODO: I bet there it a better *internal* call for this.
      Complex(coder.scalar)
    end
  end
end

