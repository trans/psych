module Psych
  # Psych's Boolean module acts a simple factory to
  # return true or false.
  module Boolean
    # Check scanned scalar and return true or false based
    # on the value.
    #
    # coder - Coder instance. [Coder]
    #
    # Returns upacked string. [string]
    def self.new_with(coder)
      coder.token ? true : false
    end
  end
end
