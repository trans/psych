class Object
  ####
  ## Initialize generic object representation.
  ##
  ## TODO: Leaving this here for now, b/c technically it could be defined for all
  ##       objects, its completely generic. (Albeit Coder is presently a bit odd.)
  ##
  ## Returns nothing.
  #def init_with(coder)
  #  case coder.type
  #  when :map
  #    coder.map.each do |k,v|
  #      k = "@#{k}" unless k.to_s.start_with?('@')
  #      instance_variable_set(k, v)
  #    end
  #  else
  #    if coder.value
  #      #raise TypeError, "#{self.class} is not a #{coder.type}."
  #      warn "#{self.class} is not a #{coder.type}, value discarded -- `#{coder.value}'" if $VERBOSE
  #    end 
  #  end
  #end

  ###
  # Get or set default Tag URI for class.
  #
  # uri - Valid YAML tag. [String]
  #
  # Returns uri. [String]
  def self.tag_uri(uri=nil)
    if uri
      @_tag_uri = uri.to_s
      Psych.add_tag(uri, self)
    else
      @_tag_uri || (name ? '!ruby/object:#{name}' : '!ruby/object')
    end
  end

  class << self
    # Deprecate: Use #tag_uri instead.
    alias :yaml_tag :tag_uri
  end

  ###
  # Get or set Tag URI for object. Tags can be local or globally unique.
  # It does not matter as long as they comply with URI character limitations.
  #
  # uri - Valid URI tag.
  #
  # Return tag. [String]
  def tag_uri(uri=nil)
    if uri
      @_tag_tag = uri.to_s
    else
      @_tag_tag || self.class.tag_uri
    end
  end

  ###
  # Set Tag URI for object.
  #
  # uri - Valid URI tag.
  #
  # Return tag. [String]
  def tag_uri=(uri)
    @_tag_uri = uri.to_s
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
