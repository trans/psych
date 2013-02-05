module Psych

  # The set of JSON schama tags only!.
  class JSONSchema < Schema
    private
    def define_defaults
      tag '!!float', Float           # tag:yaml.org,2002:float
      tag '!!int', Integer           # tag:yaml.org,2002:int
      tag '!!null', NilClass         # tag:yaml.org,2002:null
      tag '!!bool', Psych::Boolean   # tag:yaml.org,2002:bool    
      tag '!!binary', Psych::Binary  # tag:yaml.org,2002:binary
      tag '!!omap', Psych::Omap      # tag:yaml.org,2002:omap
      tag '!!set', Psych::Set        # tag:yaml.org,2002:set  
    end
  end

  JSON_SCHEMA = JSONSchema.new
end
