require 'bigdecimal'

class BigDecimal
  # TODO: This should move to bigdeciaml.rb.
  def self.new_with(coder)
    BigDecimal._load coder.scalar
  end
end

