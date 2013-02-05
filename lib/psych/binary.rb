module Psych
  # Psych's Binary module acts a simple factory to unpack
  # strings via `unpack('m')`.
  module Binary
    # Unpack a binary scalar into a string.
    #
    # coder - Coder instance. [Coder]
    #
    # Returns upacked string. [string]
    def self.new_with(coder)
      coder.scalar.unpack('m').first
    end
  end
end
