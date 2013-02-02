class Object
  # Deserialize YAML representation into a general object.
  #
  # This method is used to deserialize a YAML representation when a class
  # does not provide a `#yaml_initialize` method, which is the necessary
  # case for immutable types.
  #
  # NOTE: It would be nice is there were a universal format for generic 
  #       ruby object representation using a Factory class. That would allow
  #       us to get rid of all the specialized code in yaml_new/yaml_initialize
  #       for handling these various representations (see core_ext/string.rb).
  #
  def self.new_with(coder)
    if result = Psych.yaml_new_hacks(self, coder)
      return result
    end

    case coder.type
    when :map
      o = allocate
      coder.map.each do |k,v|
        k = "@#{k}" unless k.to_s.start_with?('@')
        o.instance_variable_set(k, v)
      end
      o
    #when :scalar
    #  coder.token
    else
      if coder.value
        #raise TypeError, "#{self} is not a #{coder.type}."
        warn "not a #{coder.type}, value discarded -- `#{self}'"
        allocate
      else
        allocate
      end 
    end
  end

  # Get or set default YAML tag for class.
  #
  # uri - Valid YAML tag. [String]
  #
  def self.yaml_tag uri=nil
    if uri
      @_yaml_tag = uri
      Psych.add_tag(uri, self)
    else
      @_yaml_tag || (name ? '!ruby/object:#{name}' : raise)  # TODO: raise what?
    end
  end

  #
  def yaml_tag
    @_yaml_tag
  end

  #
  def yaml_tag=(tag)
    @_yaml_tag = tag
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

module Psych
  # This is a shoe-horn to support BigDecimal and DateTime.
  # Eventually these should be moved to the respective class code.
  #
  def self.yaml_new_hacks(klass, coder)
    case klass.name
    when 'BigDecimal'
      # TODO: Move to bigdecimal.rb
      #def self.yaml_new(value)
      #  BigDecimal._load value
      #end
      BigDecimal._load coder.scalar
    when 'DateTime'
      # TODO: Move to date.rb
      #def self.yaml_new(value)
      #  ss.parse_time(o.value).to_datetime
      #end
      # TODO: Orginal code was
      #    ss.parse_time(o.value).to_datetime
      # But we don't have access to @ss here, the
      # value needs to be parsed first to the point
      # that DateTime can then handle it. Is there
      # any problem with this approach?
      coder.scanner.parse_time(coder.scalar).to_datetime
    end
  end
end

