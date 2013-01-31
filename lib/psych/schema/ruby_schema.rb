module Psych

  # The set of Ruby tags.
  #
  # QUERY: Shouldn't Ruby have it's own domain tag? e.g.
  #        `!tag:ruby-lang.org,1996:String`. The date might
  #        be useful in case a future version of the class
  #        changes it's representation.
  #
  # QUERY: Should BigDecimal and DateTime use the "built-in" tag schema?
  #
  # TODO: Fix Complex and Rational to use built-in tag schema.
  #
  # TODO: In bigdecimal.rb
  #     def self.yaml_new(value)
  #       BigDecimal._load value
  #     end
  #
  # TODO: In date.rb
  #     def self.yaml_new(value)
  #       # But how to get as @ss ?
  #       ss.parse_time(o.value).to_datetime
  #     end
  #
  RUBY_SCHEMA = Schema.new do |s|

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
    s.tag '!ruby/object', Object

    # Deprecate
    s.tag '!ruby/object:Complex', Complex
    s.tag '!ruby/object:Rational', Rational

    # exceptions
    s.tag /^!ruby\/exception:?(.*)?$/ do |tag, md|  # value?
      s.resolve_class(md[1])
    end

    # other classes
    s.tag /^!ruby\/object:(.*?)$/ do |tag, md|  # value?
      s.resolve_class(md[1])
    end

    # TODO: Not sure about struct, if we need this or not (see next todo note).

    s.tag /^!ruby\/struct:(.*?)$/ do |tag, md|
      s.resolve_class(md[1])
    end

    # TODO: Deprecate these? There is really no reason for these anymore, but we
    # need to change the tags the classes are emitting first.

    s.tag /^!ruby\/string:(.*?)$/ do |tag, md|
      s.resolve_class(md[1])
    end

    s.tag /^!ruby\/array:(.*?)$/ do |tag, md|
      s.resolve_class(md[1])
    end

    s.tag /^!ruby\/hash:(.*?)$/ do |tag, md|
      s.resolve_class(md[1])
    end

    # FIXME: this probably won't work
    s.tag /^!ruby\/sym(bol)?:(.*?)$/ do |tag, md|
p [tag, md]
      s.resolve_class(md[1])  #md[2]?
    end

    # TODO: Deprecate these too? More tags that are probably unnecessary.

    s.tag /^!str:(.*?)$/ do |tag, md|
      s.resolve_class(md[1])
    end

    s.tag /^!seq:(.*?)$/ do |tag, md|
      s.resolve_class(md[1])
    end

    s.tag /^!map:(.*?)$/ do |tag, md|
      s.resolve_class(md[1])
    end


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
      klass = resolve_class($1)
      if klass
        klass.allocate.replace value
      else
        value
      end
    end

    # Array subclass
    s.tag /^!ruby\/array:(.*)$/ do |tag, value|
      klass = ts.resolve_class($1)
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
      revive_hash resolve_class($1).new, o
    end

    # Symbol subclass
    s.tag /^!ruby\/sym(bol)?:?(.*)?$/ do |tag, value|
      value.to_sym
    end
=end

  end

end
