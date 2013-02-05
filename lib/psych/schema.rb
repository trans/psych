require 'psych/tag'

module Psych
  ###
  # TagTypes maps a set of tags to a set of classes or procedures
  # for instantiating the tag as a Ruby object.
  class Schema
    include Enumerable

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
      @load_tags = []
      @dump_tags = {}

      @directives = options[:directives] || {}

      # Store the block and lazy eval.
      @blocks = [block].compact

      # These are part of all schemas (unless `!!` directive is overridden).
      tag '!!str', String    # tag:yaml.org,2002:str
      tag '!!map', Hash      # tag:yaml.org,2002:map
      tag '!!seq', Array     # tag:yaml.org,2002:seq
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

    # Iterate over each tag in the schema.
    def each(&block)
      @load_tags.each(&block)
    end

    # Returns the number of tags in the schema.
    def size
      @load_tags.size
    end

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

      mtag = qualify_tag(otag)

      resolve!  # Ah, the beauty of lazy evaluation.

      type = nil
      tag = tags.find do |t|
        type = t.match?(mtag)
      end

      return nil, nil unless tag

      if (Symbol === type || String === type)
        type = resolve_class(type)
      end

      # Legacy tags can match on multiple tags for one defined tag. So,
      # accoding to test specs, we need to use the defined tag.
      mtag = tag.tag if tag.legacy? && !tag.regexp?

      return mtag, type
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
    # Returns fully qualified tag name.
    def tag(tag, type=nil, &block)
      tag = qualify_tag(tag)

      if block
        raise ArgumentError, "2 for 1" if type
        @load_tags.unshift(Tag.new(tag, &block))
      else
        # We could support symbol/string names, but they are so ugly.
        # If lazy evaluation suffices, we can leave this out.
        #case type
        #when Symbol,String
        #  @load_tags[tag] = type  #lambda{ resolve_class(type) }
        #  # TODO: does it make sense to add symbol/string to dump_tags ?
        #  @dump_tags[type.to_sym] = tag
        #else
          @load_tags.unshift(Tag.new(tag, type))
          @dump_tags[type] = tag
        #end
      end
    end

    # Define a true Tag URI compliant tag. Given a domain, year and a name,
    # a standard Tag URI definition is created, e.g. `tag:domain,year:name`.
    #
    # domain - Domain name to use in tag.
    # year   - The year the domain was established.
    # name   - Name of a domain type. [#to_s]
    # type   - Class to which this tag maps.
    # block  - A procedure the resolves to a class (use instead of `type`).
    #
    # Returns fully qualified tag name.
    def taguri_tag(domain, year, name, type=nil, &block)
      tag = "tag:#{domain},#{Integer(year)}:#{name}"
      tag(tag, type, &block)
    end

    # Define a new domain tag. Given a domain and a name, a standard
    # tag definition is created, e.g. `tag:domain:name`.
    #
    # domain - Domain name to use in tag.
    # name   - Name of a domain type. [#to_s]
    # type   - Class to which this tag maps.
    # block  - A procedure the resolves to a class (use instead of `type`).
    #
    # Options
    #
    # Returns fully qualified tag name.
    def domain_tag(domain, name, type=nil, &block)
      tag = "tag:#{domain}:#{name}"
      tag(tag, type, &block)
    end

    # Add an *instance* tag. This is NOT RECOMMENDED for adding tags
    # It is better to define your own class and use #tag.
    #
    # tag   - Valid YAML tag. [String]
    # block - Block that returns an object.
    #
    # Returns fully qualified tag name.
    def instance_tag(tag, &block)
      klass = Class.new
      klass.singleton_class.module_eval do
        define_method(:new_with) do |coder|
          block.call(coder.tag, coder.value)
        end
      end
      tag(tag, klass)
    end

    # Deprecated: Define a new offical YAML tag.
    #
    # This probably should never be used by the end user!!!
    #
    # name  - Name of built-in type. [#to_s]
    # type  - Class to which this tag maps.
    # block - A procedure the resolves to a class (use instead of `type`).
    #
    # Returns fully qualified tag name.
    def builtin_tag(name, type=nil, &block)
      tag = "tag:yaml.org,2002:#{name}"
      tag(tag, type, &block)
    end

    ## Deprecated: Define a new offical Ruby tag.
    ##
    ## This should never be used by the end user!!!
    ##
    ## name  - Name of built-in type. [#to_s]
    ## type  - Class to which this tag maps.
    ## block - A procedure the resolves to a class (use instead of `type`).
    ##
    ## Returns fully qualified tag name.
    #def ruby_tag(name, type=nil, &block)
    #  tag = "tag:ruby.yaml.org,2002:#{name}"
    #  tag(tag, type, &block)
    #end

    # Deprecated: Add a legacy *instance* tag.
    #
    # Returns fully qualified tag name.
    def legacy_instance_tag(tag, &block)
      klass = Class.new
      klass.singleton_class.module_eval do
        define_method(:new_with) do |coder|
          block.call(coder.tag, coder.value)
        end
      end
      legacy_tag(tag, klass)
    end

    # Deprecated: Define a legacy tag.
    #
    # tag   - Valid YAML tag. [String]
    # type  - Class to which the tag maps. [Class]
    # block - A procedure the resolves to a class (use instead of `type`).
    #
    # Returns fully qualified tag name.
    def legacy_tag(tag, type=nil, &block)
      tag = qualify_tag(tag)

      if block
        raise ArgumentError, "2 for 1" if type
        @load_tags.unshift(LegacyTag.new(tag, &block))
      else
        # We could support symbol/string names, but they are so ugly.
        # If lazy evaluation suffices, we can leave this out.
        #case type
        #when Symbol,String
        #  @load_tags[tag] = type  #lambda{ resolve_class(type) }
        #  # TODO: does it make sense to add symbol/string to dump_tags ?
        #  @dump_tags[type.to_sym] = tag
        #else
          @load_tags.unshift(LegacyTag.new(tag, type))
          @dump_tags[type] = tag
        #end
      end
    end
    private :legacy_tag

    # Remove tag from schema.
    #
    # tag - Valid YAML tag. [String]
    #
    def remove_tag(tag)
      mtag = qualify_tag(tag)

      target = @load_tags.find{ |t| mtag == t.tag  }

      @dump_tags.delete(target.type)
      @load_tags.delete(target)
    end

    # Absorb the tags of another TagSet object. Current tags take precedence
    # over the absorbed tags.
    #
    # other - Another schema instance. [Schema]
    #
    def absorb(other)
      raise ArgumentError unless Schema === other

      @blocks     = other.blocks + @blocks
      @load_tags  = other.load_tags + @load_tags

      @dump_tags  = other.dump_tags.merge @dump_tags
      @directives = other.directives.merge @directives
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

    # Fully qualify a tag by substituting prefixes.
    #
    # tag - Valid YAML tag. [String]
    #
    # Returns qualified tag string. [String]
    def qualify_tag(tag)
      return nil unless tag
      return tag if Regexp === tag

      # Local tags that start with `!tag:` treat as domain tags.
      #
      # TODO: Technically, there is no reason to do this except that's how
      # it has been working. It is doubtul anyone has ever used it, and
      # should probably be deprecated.
      if tag =~ /^[!\/]?tag\:/
        tag = tag.sub(/^[!\/]*/, '')
      end

      # For domain tags only, replace slash after a date with a colon.
      # Deprecated this behaviour. They really are two different tags.
      #if tag.start_with?('tag:')
      #  tag = tag.sub(/(,\d+)\//, '\1:')
      #end

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
