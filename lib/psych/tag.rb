module Psych
  ###
  # Tag class encapsulate a tag added to a Schema.
  class Tag
    ###
    # Initialize new Tag instance.
    #
    # tag   - URI or Regexp. [String,Regexp]
    # type  - Associated class (or factory module).
    # block - Used in place of type to calculate class.
    #
    # Returns nothing.
    def initialize(tag, type=nil, &block)
      raise ArgumentError if type && block

      @tag   = tag
      @type  = type
      @block = block
    end

    ###
    # Tag name or tag name regexp.
    attr :tag

    ###
    # Global tags are suppoesed to be valid URIs. Local tags
    # valid URI fragments.
    alias :uri :tag

    ###
    # Specific class the tag is associated with. But will be `nil` if 
    # the class is calcuated via a procedure instead.
    attr :type

    ###
    # Does a given tag (uri) match that of the Tag instance?
    #
    # tag - Tag URI. [String]
    #
    # Returns macting type. [Class]
    def match?(tag)
      type_get(regexp? ? @tag.match(tag) : @tag == tag)
    end

    ###
    # Is this Tag object the same as another? They are
    # if their tag uri's are equal.
    #
    # other - Another Tag instance. [Tag]
    #
    # Return true or false. [Boolean]
    def ==(other)
      @tag == other.tag
    end

    ###
    # Is this a Regexp based tag?
    #
    # Returns true or false. [Boolean]
    def regexp?
      Regexp === @tag
    end

    ###
    # Is this a legacy tag? No, it is not!
    #
    # Returns true or false. [Boolean]
    def legacy?
      false
    end

    # This was for debuging.
    #def inspect
    #  @tag.inspect
    #end

  private

    ###
    # This is the biggest API change (2.x+). It means using a block to *instantiate* a tag type
    # is completely deprecated. Instead, the block must return a class. So all tags must be
    # associated with a class, though more then one tag can be associated with the same class.
    #
    # md - Match result. [MatchData,Boolean]
    #
    # Returns the associated class. [Class,Module]
    def type_get(md)
      return nil unless md
      return @type unless @block

      Regexp === @tag ? call(md) : call()
    end

    ###
    # Execute the block, and get the topy surprise inside!
    #
    # md - MatchData, if Regexp-based tag.
    #
    # Returns the associated class. [Class,Module]
    def call(*md)
      @block.call(@tag, *md)
    end
  end

  ###
  # Deprecated: Legacy tags are strictly used for backward compatability.
  class LegacyTag < Tag
    ###
    # Does a given tag (uri) match that of the Tag instance?
    #
    # tag - Tag URI. [String]
    #
    # Returns macting type. [Class]
    def match?(tag)
      type = nil
      tag_variations(tag).find do |tv|
        type = type_get(regexp? ? @tag.match(tv) : @tag == tv)
      end
      type
    end

    ###
    # Is this a legacy tag? Yes, it is!
    #
    # Returns true or false. [Boolean]
    def legacy?
      true
    end

  private

    ###
    # Look at all those shiny possibilities! ;)
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
