module Psych
  # Just acts as a factory.
  class Binary
    def self.new_with(coder)
      coder.scalar.unpack('m').first
    end
  end
end
