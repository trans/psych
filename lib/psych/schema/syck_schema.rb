module Psych

  # This Schema is legacy and is deprecated. It containes tags that were
  # supported by the original Syck library.
  #
  SYCK_SCHEMA = Schema.new do |s|

    # TODO: Deprecate b/c YAML already has means for explict strings using quotes.
    s.tag '!str', String

    s.tag '!set', Psych::Set
    s.tag '!omap', Psych::Omap

    # See yaml_tree.rb L#240
    s.tag '!binary', Psych::Binary

  end

end
