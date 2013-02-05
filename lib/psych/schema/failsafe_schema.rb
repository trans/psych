module Psych

  # The set of core YAML tag types *only*.
  #
  FAILSAFE_SCHEMA = Schema.new do |s|
    # These are the default tags of all Schema.
    # s.tag '!!str', String  # tag:yaml.org,2002:str
    # s.tag '!!map', Hash    # tag:yaml.org,2002:map
    # s.tag '!!seq', Array   # tag:yaml.org,2002:seq
  end

end
