module Psych
  ###
  # Psych's Set class is little more than a Hash.
  # 
  # TODO: Why not use Ruby's own Set class?
 class Set < ::Hash
    ###
    # Initialize Set instance using a Coder.
    #
    # coder - Coder instance. [Coder]
    #
    # Returns nothing.
    def init_with(coder)
      replace coder.map
    end
  end
end
