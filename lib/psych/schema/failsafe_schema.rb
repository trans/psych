module Psych

  # The set of core YAML tag types.
  FAILSAFE_SCHEMA = Schema.new do |ts|
    # tag:yaml.org,2002:str
    ts.add '!!str', String

    # tag:yaml.org,2002:map
    ts.add '!!map', Hash

    # tag:yaml.org,2002:seq
    ts.add '!!seq', Array
  end

end
