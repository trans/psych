module Psych

  # The set of Ruby tags.
  #
  # QUERY: Shouldn't Ruby have it's own domain tag? e.g.
  #        `!<tag:ruby-lang.org,1996:String>`.
  #
  # TODO: Fix Complex and Rational to use built-in tag schema.
  #
  RUBY_SCHEMA = Schema.new do |s|

    # TODO: Deprecate the following three "shortcuts". The emitter should
    #       be using `!ruby/` tags.

    s.tag /^!str:(.*?)$/ do |tag, md|
      s.resolve_class(md[1])
    end

    s.tag /^!seq:(.*?)$/ do |tag, md|
      s.resolve_class(md[1])
    end

    s.tag /^!map:(.*?)$/ do |tag, md|
      s.resolve_class(md[1])
    end

    # TODO: Deprecate the following. There is no need to have `string`, `array`
    #       or `hash` in the subclass names anymore, but we need to change
    #       the tags the emitter puts out first.

    s.tag /^!ruby\/string:(.*?)$/ do |tag, md|
      s.resolve_class(md[1])
    end

    s.tag /^!ruby\/array:(.*?)$/ do |tag, md|
      s.resolve_class(md[1])
    end

    s.tag /^!ruby\/hash:(.*?)$/ do |tag, md|
      s.resolve_class(md[1])
    end

    # FIXME: this probably won't work anyway
    s.tag /^!ruby\/sym(bol)?:(.*?)$/ do |tag, md|
      s.resolve_class(md[1])  #md[2]?
    end

    # TODO: Not sure about struct, if we need this or not (see next todo note).
    s.tag /^!ruby\/struct:(.*?)$/ do |tag, md|
      s.resolve_class(md[1])
    end

    # exceptions
    s.tag /^!ruby\/exception:(.*)?$/ do |tag, md|  # value?
      s.resolve_class(md[1]) || ::Exception
    end

    # other classes
    s.tag /^!ruby\/object:(.*?)$/ do |tag, md|  # value?
      s.resolve_class(md[1])
    end

    # Deprecate: These are built-in class.
    s.tag '!ruby/object:Complex', Complex
    s.tag '!ruby/object:Rational', Rational

    # built-in class
    s.tag '!ruby/string', String
    s.tag '!ruby/array', Array
    s.tag '!ruby/hash', Hash
    s.tag '!ruby/symbol', Symbol
    s.tag '!ruby/sym', Symbol   # deprecate
    s.tag '!ruby/range', Range
    s.tag "!ruby/regexp", Regexp
    s.tag '!ruby/class', Class
    s.tag '!ruby/module', Module
    s.tag '!ruby/fixnum', Fixnum
    s.tag '!ruby/float', Float
    s.tag '!ruby/complex', Complex
    s.tag '!ruby/rational', Rational
    s.tag '!ruby/exception', ::Exception
    s.tag '!ruby/struct', Struct
    s.tag '!ruby/object', Object

=begin
    # Object
    s.tag /^!ruby\/object:?(.*)?$/ do |tag, value|
      name = $1 || 'Object'
      if name == 'Complex'
        Complex(value['real'], value['image'])
      elsif name == 'Rational'
        Rational(value['numerator'], value['denominator'])
      else
        klass = s.resolve_class(name)
        obj = s.revive((klass || Object), o)
        obj
      end
    end

    # String subclass
    s.tag /^!(?:str|ruby\/string)(?::(.*))?/ do
      klass = s.resolve_class($1)
      if klass
        klass.allocate.replace value
      else
        value
      end
    end

    # Array subclass
    s.tag /^!ruby\/array:(.*)$/ do |tag, value|
      klass = s.resolve_class($1)
      list  = register(o, klass.allocate)

      #members = Hash[o.children.map { |c| accept c }.each_slice(2).to_a]
      list.replace value['internal']
      value['ivars'].each do |ivar, v|
        list.instance_variable_set ivar, v
      end
      list
    end

    # Hash subclass
    s.tag /^!map:(.*)$/, /^!ruby\/hash:(.*)$/ do
      revive_hash s.resolve_class($1).new, o
    end
=end

  end

end
