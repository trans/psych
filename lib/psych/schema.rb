module Psych

# FIXME: FUCK! TAG ORDER IS NOT BEING HONORED. HAVE TO REFACTOR!!!

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

    # %TAG directives.
    attr_reader :directives

    # Tag table in the form of `tag => class`.
    attr_reader :load_tags

    # Tag table in the form of `class => tag`.
    #
    # TODO: Technically more than one tag can map to the same class. So we might
    #       change this to an array of tags. Presently only the last tag to
    #       be defined is mapped to the class.
    #
    attr_reader :dump_tags

    # Add a lazy schema procedure. The procedure does not get called until #resolve!
    # is called. This happend when #find in utilized, for instance.
    #
    # TODO: Need a better name for this method ?
    #
    def apply(&block)
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

      mtag = normalize_tag(otag)

      resolve!  # Ah, the beauty of lazy evaluation.

      md = nil
      tag, type = tags.find do |t, _|
        if Regexp === t
          md = t.match(mtag)
        else
          t == mtag #|| t.sub('tag:','!') == mtag
        end
      end

      # This is the biggest API change (2.x+). It means using a block to *instantiate* a tag type
      # is completely deprecated. Instead, the block must return a class. So all tags must be
      # associated with a class, though more then one tag can be associated with the same class.
      if Proc === type
        type = (Regexp === tag ? type.call(tag, md) : type.call(tag))
        raise ArgumentError, "not a class -- `#{type}'" unless Class === type
      end

      if (Symbol === type || String === type)
        type = resolve_class(type)
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
      tag = "tag:#{domain}:#{name}"
      tag(tag, type, &block)
      #tag("tag:#{name}", type, &block)  # deprecated this shortcut, with schemas
                                         # the user needs to be explicit.
    end

    # Deprecated: Define a new offical YAML tag.
    #
    # This probably should never be used by the end user!!!
    #
    # name  - Name of built-in type. [#to_s]
    # type  - Class to which this tag maps.
    # block - A procedure the resolves to a class (use instead of `type`).
    #
    def builtin_tag(name, type=nil, &block)
      tag = "tag:yaml.org,2002:#{name}"
      tag(tag, type, &block)
    end

    # Deprecated: Define a new offical Ruby tag.
    #
    # This should never be used by the end user!!!
    #
    # name  - Name of built-in type. [#to_s]
    # type  - Class to which this tag maps.
    # block - A procedure the resolves to a class (use instead of `type`).
    #
    def ruby_tag(name, type=nil, &block)
      tag = "tag:ruby.yaml.org,2002:#{name}"
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
    # TODO: Good question here, is order well maintained by #merge? Mot so sure!
    #       Mehtod #reverse_merge is used in hopes that will do the right thing.
    #       But if not, we have two choices: Either use an Array instead of a
    #       Hash (slow) or support a list of Schema for the Schema option (maybe kind of sucks).
    #
    # other - Another schema instance. [Schema]
    #
    def absorb(other)
      raise ArgumentError unless Schema === other
      @blocks     = @blocks + other.blocks
      @directives = directives.reverse_merge(other.directives)
      @load_tags  = load_tags.reverse_merge(other.load_tags)
      @dump_tags  = dump_tags.reverse_merge(other.dump_tags)
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
    # name - The name of a class. [Symbol,String]
    #
    # Returns the resolved class, or nil if not resolved. [Class,nil]
    def resolve_class name
      #Psych.resolve_class name
      return nil unless name and not name.empty?
      retried = false
      begin
        path2class(name)  # Ruby 2.0: Object.const_get(name) ?
      rescue ArgumentError, NameError => ex
        unless retried
          name    = "Struct::#{name}"
          retried = ex
          retry
        end
        raise retried
      end
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

      # Local tags that start with `!tag:` treat as domain tags.
      # TODO: Technically, there is no reason to do this except that's how
      # it has been working. It is doubtul anyone has ever used it.
      if tag =~ /^[!\/]?tag\:/
        tag = tag.sub(/^[!\/]*/, '')
      end

      # For domain tags only, replace slash after a date with a colon.
      # TODO: Again, technically not necessary.
      if tag.start_with?('tag:')
        tag = tag.sub(/(,\d+)\//, '\1:')
      end

      # How to handle regex in this case? Maybe we have to match with directives after the fact, in #find.
      if tag.start_with?('!')
        @directives.each do |handle, prefix|
          if tag.start_with?(handle)
            return tag.sub(handle, prefix)
          end
        end
      end

      if tag.start_with?('!!')
        tag = ['tag', 'yaml.org,2002', tag.sub('!!', '')].join ':'
      end

      return tag
    end

  end

end
