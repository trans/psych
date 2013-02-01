module Psych

  # The set of core YAML tag types.
  #
  # TODO: This should be in *all* Schema.
  #
  FAILSAFE_SCHEMA = Schema.new do |s|
    # tag:yaml.org,2002:str
    s.tag '!!str', String

    # tag:yaml.org,2002:map
    s.tag '!!map', Hash

    # tag:yaml.org,2002:seq
    s.tag '!!seq', Array
  end

end
