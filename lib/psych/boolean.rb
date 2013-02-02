module Psych
  class Boolean
    def self.new_with(coder)
      coder.token ? true : false
    end
  end
end
