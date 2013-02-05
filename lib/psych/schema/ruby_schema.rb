module Psych
  ###
  # The set of Ruby core class tags.
  #
  # TODO: To be technically precise, Ruby tags should be globally unique domain
  #       tags, not local tags, e.g.`!<tag:ruby-lang.org,1996:String>`.
  #       End users they should use `%TAG !ruby! tag:ruby-lang.org,1996:` directive
  #       and prefix all Ruby tags with `!ruby!`, e.g. `!ruby!String`.
  #
  # TODO: Emitter can be adjusted for short-version of tag for Complex and Rational.
  #
  RUBY_SCHEMA = Schema.new do |s|
    # Deprecate: Once BigDecimal defines new_with for itself.
    # Note, should BigDecimal get a special tag like the core classes?
    s.tag '!ruby/object:BigDecimal' do |tag|
      require 'psych/core_ext/bigdecimal'
      BigDecimal
    end

    # Deprecate: Once DateTime defines new_with itself.
    # Note, should DateTime get a special tag like the core classes?
    s.tag '!ruby/object:DateTime' do |tag|
      require 'psych/core_ext/date'
      DateTime
    end

    # TODO: These are built-in, so should they not be like the others?
    #       But currently these are what are emitted.
    s.tag '!ruby/object:Complex', Complex
    s.tag '!ruby/object:Rational', Rational

    # FIXME: Psych has no special tag for actual Struct b/c it is being
    #        used by the emitter for anonymous stucts in OBJECT_SCHEMA.
    s.tag '!ruby/object:Struct', ::Struct

    s.tag '!ruby/string', ::String
    s.tag '!ruby/array', ::Array
    s.tag '!ruby/hash', ::Hash
    s.tag '!ruby/symbol', ::Symbol
    s.tag '!ruby/sym', ::Symbol   # TODO: deprecate!
    s.tag '!ruby/range', ::Range
    s.tag "!ruby/regexp", ::Regexp
    s.tag '!ruby/class', ::Class
    s.tag '!ruby/module', ::Module
    s.tag '!ruby/fixnum', ::Fixnum
    s.tag '!ruby/float', ::Float
    s.tag '!ruby/complex', ::Complex  # emitter doesn't use this
    s.tag '!ruby/rational', ::Rational  # emitter doesn't use this
    s.tag '!ruby/exception', ::Exception
    s.tag '!ruby/object', ::Object
  end
end
