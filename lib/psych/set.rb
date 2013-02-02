module Psych
 class Set < ::Hash
    def init_with(coder)
      replace coder.map
    end
  end
end

