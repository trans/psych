module Psych

  ###
  # TagTypes maps a set of tags to a set of classes or procedures
  # for instantiating the tag as a Ruby object.
  class Schema

    # Initialize new Schema instance.
    #
    # options - Schema options.
    # block   - Lazy evaluated tag definition procedure.
    #
    # Options
    #
    #   :directives - %TAG directives preform easy namespacing via prefix
    #                 substitution.
    #
    def initialize(options={}, &block)
      @load_tags = {}
      @dump_tags = {}

      @directives = options[:directives] || {}

      # Store the block and lazy eval instead?
      @blocks = [block].compact
    end

    # Tag table in the form of `tag => class`.
    attr_reader :load_tags

    # Tag table in the form of `class => tag`.
    #
    # TODO: Technically this is wrong, as more than one tag can map to the same class.
    #       This should be changed to any array of tags. Presently only the last tag to
    #       be defined to map to the class. (Make it the first instead?)
    #
    attr_reader :dump_tags

    # Add a lazy schema procedure. The procedure does not get called until #resolve!
    # is called. This happend when #find in utilized, for instance.
    #
    # TODO: Need a name for this method.
    #
    def __(&block)
      @blocks << block
    end

    # Resolve intialization block.
    def resolve!
      until @blocks.empty?
        @blocks.shift.call(self)
      end
    end

    # Find a matching tag.
    #
    # otag - Tag to search. [String,Regexp]
    #
    # Returns matching tag and tag type. [Array<String,Class>]
    def find(otag)
      return nil, nil unless otag

      resolve!  # Ah, the beauty of lazy evaluation.

      md = nil
      tag, type = tags.find do |t, _|
        if Regexp === t
          md = t.match(otag)
        else
          t == otag
        end
      end

      # TODO: Will this be okay? It means using a block to instantiate a tag type is completely deprecated.
      #       Instead the block must return a class. So all tags must be associated with a class, though more
      #       then one tag can be associated with the same class.
      if Proc === type
        type = type.call(otag, md)
        raise ArgumentError, "not a class -- `#{type}'" unless Class === type
      end

      if (Symbol === type || String === type)
        type = resolve_class(type)  # TODO: Does lookup need to be relative to the block's binding?
      end

      return tag, type
    end

    # Map of resolved tags, in the form of `tag => class`.
    #
    # Returns tag map. [Hash]
    def tags
      #resolve!  # TODO: Should we resolve here?
      @load_tags
    end

    # Define a tag.
    #
    # tag   - Valid YAML tag. [String]
    # type  - Class to which the tag maps. [Class]
    # block - A procedure the resolves to a class (use instead of `type`).
    #
    def tag(tag, type=nil, &block)
      tag = normalize_tag(tag)

      if block
        raise ArgumentError, "2 for 1" if type
        @load_tags[tag] = block
      else
        # We could support symbol/string names, but they are so ugly.
        # If lazy evaluation suffices, we can leave this out.
        #case type
        #when Symbol,String
        #  @load_tags[tag] = type  #lambda{ resolve_class(type) }
        #  # TODO: does it make sense to add symbol/string to dump_tags ?
        #  @dump_tags[type.to_sym] = tag
        #else
          @load_tags[tag]  = type
          @dump_tags[type] = tag
        #end
      end
    end

    # Define a new domain tag. Given a domain and a name a standard
    # tag definition is created, e.g. `tag:domain:name`.
    #
    # domain - Domain name to use in tag.
    # name   - Name of a domain type. [#to_s]
    # type   - Class to which this tag maps.
    # block  - A procedure the resolves to a class (use instead of `type`).
    #
    def domain_tag(domain, name, type=nil, &block)
      tag = ['tag', domain, name].join ':'
      tag(tag, type, &block)
    end

    # Define a new YAML tag.
    #
    # TODO: This probably should never be used by the end user.
    #
    # name  - Name of built-in type. [#to_s]
    # type  - Class to which this tag maps.
    # block - A procedure the resolves to a class (use instead of `type`).
    #
    def builtin_tag(name, type=nil, &block)
      tag = ['tag', 'yaml.org,2002', name].join ':'
      tag(tag, type, &block)
    end

    # Remove tag from schema.
    #
    # tag - Valid YAML tag. [String]
    #
    def remove_tag(tag)
      tag = normalize_tag(tag)

      @dump_tags.delete(@load_tags[tag])
      @load_tags.delete(tag)
    end

    # Absorb the tags of another TagSet object. Current tags take
    # precedence over the added tags.
    #
    # TODO: Good question here, is order well maintained by #merge?
    #
    # other - Another schema instance. [Schema]
    #
    def absorb(other)
      raise ArgumentError unless Schema === other
      @blocks    = other.blocks + @blocks
      @load_tags = other.load_tags.merge(load_tags)
      @dump_tags = other.dump_tags.merge(dump_tags)
    end

    # Add this Schema with another Schema producing a new Schema.
    #
    # other - Another schema instance. [Schema]
    #
    # Returns new combined schema. [Schema]
    def +(other)
      tt = Schema.new
      tt.absorb(self)
      tt.absorb(other)
      tt
    end

    # Helper method to convert `name` to a class. This actually
    # just calls `Psych.resolve_class`.
    #
    # TODO: Do we need to pass binding for proper lookup?
    #
    # name - The name of a class. [Symbol,String]
    #
    # Returns the resolved class, or nil if not resolved. [Class,nil]
    def resolve_class name
      Psych.resolve_class name
    end

  protected

    # TODO: Better name.
    def blocks
      @blocks
    end

  private

    # Normalize tag by substituting prefixes.
    #
    # tag - Valid YAML tag. [String]
    #
    def normalize_tag(tag)
      return nil unless tag
      return tag if Regexp === tag

      tag = tag.to_s
      tag = tag.sub(/(,\d+)\//, '\1:') if String === tag

      # How to handle regex in this case ?
      @directives.each do |handle, prefix|
        if tag.start_with?(handle)
          return tag.sub(handle, prefix)
        end
      end

      # TODO: this correct?
      if tag.start_with?('!!')
        return ['tag', 'yaml.org,2002', tag.sub('!!', '')].join ':'
      end

      tag
    end

  end

end
