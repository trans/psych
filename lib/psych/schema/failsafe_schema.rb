module Psych

  # Failsafe schema tags only!
  #
  class FailsafeSchema < Schema
    private
    def define_defaults
      tag '!!str', String  # tag:yaml.org,2002:str
      tag '!!map', Hash    # tag:yaml.org,2002:map
      tag '!!seq', Array   # tag:yaml.org,2002:seq
    end
  end

end
