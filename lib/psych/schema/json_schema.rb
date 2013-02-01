module Psych

  # The set of extra YAML tags.
  JSON_SCHEMA = Schema.new do |s|

    # tag:yaml.org,2002:float
    s.tag '!!float' do |tag, value|
      value  # TODO: string scanner takes care of it?
    end

    # tag:yaml.org,2002:int
    s.tag '!!int' do |tag, value|
      value  # TODO: string scanner takes care of it?
    end

    # tag:yaml.org,2002:null
    s.tag '!!null' do |tag, value|
      nil
    end

    # tag:yaml.org,2002:bool
    s.tag '!!bool' do |tag, value|
      !!value
    end

    # tag:yaml.org,2002:binary
    s.tag '!!binary' do |tag, value|
      value.unpack('m').first
    end

    # tag:yaml.org,2002:omap
    s.tag '!!omap', Psych::Omap

    # TODO: why not Ruby's set class?

    # tag:yaml.org,2002:set  
    s.tag '!!set', Psych::Set
  end

end
