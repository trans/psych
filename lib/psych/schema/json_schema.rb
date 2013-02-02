module Psych

  # The set of extra YAML tags.
  JSON_SCHEMA = Schema.new do |s|

    # tag:yaml.org,2002:float
    s.tag '!!float', Float

    # tag:yaml.org,2002:int
    s.tag '!!int', Integer

    # tag:yaml.org,2002:null
    s.tag '!!null', NilClass

    # tag:yaml.org,2002:bool
    s.tag '!!bool', Psych::Boolean

    # tag:yaml.org,2002:binary
    s.tag '!!binary', Psych::Binary

    # tag:yaml.org,2002:omap
    s.tag '!!omap', Psych::Omap

    # TODO: why not Ruby's set class?

    # tag:yaml.org,2002:set  
    s.tag '!!set', Psych::Set
  end

end
