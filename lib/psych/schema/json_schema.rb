module Psych

  # The set of extra YAML tags.
  JSON_SCHEMA = Schema.new do |ts|

    # tag:yaml.org,2002:float
    ts.add '!!float' do |tag, value|
      value  # TODO: string scanner takes care of it?
    end

    # tag:yaml.org,2002:int
    ts.add '!!int' do |tag, value|
      value  # TODO: string scanner takes care of it?
    end

    # tag:yaml.org,2002:null
    ts.add '!!null' do |tag, value|
      nil
    end

    # tag:yaml.org,2002:bool
    ts.add '!!bool' do |tag, value|
      !!value
    end

    # tag:yaml.org,2002:binary
    ts.add '!!binary' do |tag, value|
      value.unpack('m').first
    end

    # tag:yaml.org,2002:omap
    ts.add '!!omap', Psych::Omap

    # TODO: why not Ruby's set class?

    # tag:yaml.org,2002:set  
    ts.add '!!set', Psych::Set
  end

end
