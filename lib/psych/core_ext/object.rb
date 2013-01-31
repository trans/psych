class Object
  #
  def self.yaml_tag url=nil
    Psych.add_tag(url, self)
  end

  # Deserialize YAML representation into a general object.
  #
  # This method is used to deserialize a YAML representation when a class
  # does not provide a `#yaml_initialize` method, which is the necessary
  # case for immutable types.
  #
  def self.yaml_new(value)
    #raise ArgumentError unless StateImage === value
    if StateImage === value
      o = allocate
      value.each{ |k,v| o.instance_variable_set("@#{k}", v) }
      o
    end
  end

  # FIXME: rename this to "to_yaml" when syck is removed

  ###
  # call-seq: to_yaml(options = {})
  #
  # Convert an object to YAML.  See Psych.dump for more information on the
  # available +options+.
  def psych_to_yaml options = {}
    Psych.dump self, options
  end
  remove_method :to_yaml rescue nil
  alias :to_yaml :psych_to_yaml
end

