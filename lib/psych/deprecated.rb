require 'date'

module Psych
  # Location of this deprecated.rb script.
  DEPRECATED = __FILE__ # :nodoc:

  module DeprecatedMethods # :nodoc:
    attr_accessor :taguri
    attr_accessor :to_yaml_style
  end

  def self.quick_emit thing, opts = {}, &block # :nodoc:
    warn "#{caller[0]}: YAML.quick_emit is deprecated" if $VERBOSE && !caller[0].start_with?(File.dirname(__FILE__))
    target = eval 'self', block.binding
    target.extend DeprecatedMethods
    metaclass = class << target; self; end
    metaclass.send(:define_method, :encode_with) do |coder|
      target.taguri        = coder.tag
      target.to_yaml_style = coder.style
      block.call coder
    end
    target.psych_to_yaml unless opts[:nodump]
  end

  # This method is deprecated, use Psych.load_stream instead.
  def self.load_documents yaml, &block
    if $VERBOSE
      warn "#{caller[0]}: load_documents is deprecated, use load_stream"
    end
    list = load_stream yaml
    return list unless block_given?
    list.each(&block)
  end

  def self.detect_implicit thing
    warn "#{caller[0]}: detect_implicit is deprecated" if $VERBOSE
    return '' unless String === thing
    return 'null' if '' == thing
    ScalarScanner.new.tokenize(thing).class.name.downcase
  end

  ###
  # Deprectated: Make your own class and use #tag instead.
  #
  # This method creates a legacy tag which matches many different
  # actual tags for backward compatability.
  #
  # domain - Valid domain name. [string]
  # name   - Tag's name, used as URI fragment. [String]
  #
  # Returns `tag:<domain>:<name>` tag uri. [String]
  def self.add_domain_type domain, name, &block
    warn "#{caller[0]}: add_domain_type is deprecated" if $VERBOSE
    tags = []
    tags << "tag:#{domain}:#{name}"
    tags << "tag:#{name}"   # This is so bad!

    tags.each do |tag|
      @global_schema.legacy_instance_tag(tag, &block)
    end

    tags
  end

  ###
  # Deprectated: Use `add_tag('tag:yaml.org,2002:<name>)` if you really
  # have to do this.
  #
  # name - Type name. [String]
  #
  # Returns `tag:yaml.org,2002:<name>` tag uri. [String]
  def self.add_builtin_type name, &block
    warn "#{caller[0]}: add_builtin_type is deprecated" if $VERBOSE
    tag = "tag:yaml.org,2002:#{name}"
    @global_schema.legacy_instance_tag(tag, &block)
  end

  def self.add_ruby_type name, &block
    warn "#{caller[0]}: add_ruby_type is deprecated" if $VERBOSE
    tag = "tag:ruby.yaml.org,2002:#{name}"
    @global_schema.legacy_instance_tag(tag, &block)
  end

  def self.add_private_type tag, &block
    warn "#{caller[0]}: add_private_type is deprecated, use add_tag" if $VERBOSE
    tag = "!x-private:#{tag}"
    @global_schema.instance_tag(tag, &block)
  end

  ###
  # Deprecated: Remove a tag from the global schema.
  #
  # IMPORTANT: This can't work exactly like it did, b/c tags are only
  # stored by their fully qualified tag name. To remove a legacy type,
  # e.g. `add_builtin_type('foo')` would require 'tag:yaml.org,2002:foo'
  # to removed it, not just 'foo'. So, this searches all the tags for
  # best possible legacy matches it can muster and removes all of them,
  # but it is not 100% equivalent to pre-2.0 behaviour!
  #
  # TODO: Improve compatibility as much as possible.
  #
  # Returns list of tags removed. [Array<String>]
  def self.remove_type tag
    warn "#{caller[0]}: remove_type is deprecated, use remove_tag" if $VERBOSE
    list = @global_schema.tags.select do |t|
      case t.uri
      when /tag:yaml.org,2002:#{tag}/ then true
      when /tag:#{tag}/ then true
      when tag then true
      else false
      end
    end
    list.each do |t|
      @global_schema.remove_tag t
    end
    list
  end

  # FIXME
  def self.tagurize thing
    warn "#{caller[0]}: add_private_type is deprecated" if $VERBOSE
    return thing unless String === thing
    "tag:yaml.org,2002:#{thing}"
  end

  def self.read_type_class type, reference
    warn "#{caller[0]}: read_type_class is deprecated" if $VERBOSE
    _, _, type, name = type.split ':', 4

    reference = name.split('::').inject(reference) do |k,n|
      k.const_get(n.to_sym)
    end if name
    [type, reference]
  end

  def self.object_maker klass, hash
    warn "#{caller[0]}: object_maker is deprecated" if $VERBOSE
    klass.allocate.tap do |obj|
      hash.each { |k,v| obj.instance_variable_set(:"@#{k}", v) }
    end
  end
end

class Object
  undef :to_yaml_properties rescue nil
  def to_yaml_properties # :nodoc:
    instance_variables
  end
end
