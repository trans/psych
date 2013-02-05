module Psych
  ###
  # OBJECT_SCHEMA is an open object schema. It allows any end-developer Ruby
  # class to be deserialized via YAML.
  #
  # The primary local tag pattern is `!ruby/object:ClassName`.
  #
  # TODO: Really this tag pattern could be simplified to just `!ruby:ClassName`
  #       or `!ruby/Classname`.
  OBJECT_SCHEMA = Schema.new do |s|

    # TODO: Deprecate the following three "shortcuts". The emitter needs
    #       only the `!ruby/object:` prefex to do any of these any way.

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
    #       or `hash` in the subclass names anymore. But we need to change
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

    # TODO: Probably useless anyway, so why is it here?
    s.tag /^!ruby\/sym(bol)?:(.*?)$/ do |tag, md|
      s.resolve_class(md[1])  #md[2]?
    end

    # TODO: This is the only one, not sure if special struct space
    #       is needed/helpful or not.
    s.tag /^!ruby\/struct:(.*?)$/ do |tag, md|
      s.resolve_class(md[1])
    end

    # TODO: Techinally don't need this either.
    s.tag /^!ruby\/exception:(.*)?$/ do |tag, md|
      s.resolve_class(md[1]) || ::Exception
    end

    # All other classes. This is really all we need.
    s.tag /^!ruby\/object:(.*?)$/ do |tag, md|
      s.resolve_class(md[1]) || Object   # not an error if not resoved?
    end

    # FIXME: This is being used for anonymous structs by the emitter.
    #        But it needs to be something else, so this tag can be 
    #        used for actual Struct class. Maybe `!ruby/astruct`.
    s.tag '!ruby/struct', Struct::Factory
  end
end
