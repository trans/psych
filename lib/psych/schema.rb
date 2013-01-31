module Psych

  ###
  # TagTypes maps a set of tags to a set of classes or procedures
  # for instantiating the tag as a Ruby object.
  class Schema

    # Initialize new Schema instance.
    def initialize(options={})
      @load_tags = {}
      @dump_tags = {}

      @directives = options[:directives] || {}

      yield self if block_given?
    end

    attr_reader :load_tags
    attr_reader :dump_tags

    def tags
      @load_tags
    end

    def tag(tag, type=nil, &block)
      tag = normalize_tag(tag)

      @load_tags[tag]  = type || block
      @dump_tags[type] = tag unless block
    end
    alias :add :tag

    def domain_tag(domain, name, type=nil, &block)
      tag = ['tag', domain, name].join ':'
      tag(tag, type, &block)
    end

    def builtin_tag(name, type=nil, &block)
      tag = ['tag', 'yaml.org,2002', name].join ':'
      tag(tag, type, &block)
    end

    def remove(tag)
      tag = normalize_tag(tag)

      @dump_tags.delete(@load_tags[tag])
      @load_tags.delete(tag)
    end

    # Absorb the tags of another TagSet object. Current tags take
    # precedence over the added tags.
    #
    # TODO: Good question here, is order well maintained by #merge?
    #
    def absorb(other)
      raise ArgumentError unless Schema === other
      @load_tags = other.load_tags.merge(load_tags)
      @dump_tags = other.dump_tags.merge(dump_tags)
    end

    # Add this TagSet with another TagSet producing a new TagSet.
    def +(other)
      tt = Schema.new
      tt.absorb(self)
      tt.absorb(other)
      tt
    end

    # Helper method to convert +klassname+ to a class.
    # Actually calls `Psych.resolve_class`.
    def resolve_class klassname
      Psych.resolve_class klassname
    end

    private

    #
    def normalize_tag(tag)
      if String === tag
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
      end

      tag
    end

  end

end
