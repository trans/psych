module Psych

  class Tag
    def initialize(tag, type=nil, &block)
      raise ArgumentError if type && block

      @tag   = tag
      @type  = type
      @block = block
    end

    # Tag name or match pattern.
    attr :tag

    # Specific class the tag is associated with. But will be `nil` if 
    # the class is calcuated via a procedure instead.
    attr :type

    #
    # Returns matcing type. [Class]
    def match?(tag)
      type_get(regexp? ? @tag.match(tag) : @tag == tag)
    end

    def ==(other)
      @tag == other.tag
    end

    def regexp?
      Regexp === @tag
    end

    def inspect
      @tag.inspect
    end

    def legacy?
      false
    end

  private

    # This is the biggest API change (2.x+). It means using a block to *instantiate* a tag type
    # is completely deprecated. Instead, the block must return a class. So all tags must be
    # associated with a class, though more then one tag can be associated with the same class.
    def type_get(md)
      return nil unless md
      return @type unless @block

      Regexp === @tag ? call(md) : call()
    end

    def call(*md)
      @block.call(@tag, *md)
    end

  end

  # Deprecated. This is strictly used for backward compatability.
  class LegacyTag < Tag

    def match?(tag)
      type = nil
      tag_variations(tag).find do |tv|
        type = type_get(regexp? ? @tag.match(tv) : @tag == tv)
      end
      type
    end

    def legacy?
      true
    end

  private

    def tag_variations(tag)
      tv = [tag]
      tv << tag.sub(/^tag:/, '!tag:')
      tv << tag.sub(/^tag:/, '!')
      tv << tag.sub(/^[!]/, 'tag:')
      tv << tag.sub(/^[!]/, '')
      tv.dup.each do |v|
        tv << v.sub(/(,\d+):/, '\1/') if v =~ /,\d+:/
        tv << v.sub(/(,\d+)\//, '\1:') if v =~ /,\d+\//
      end
      tv.uniq
    end

  end

end
