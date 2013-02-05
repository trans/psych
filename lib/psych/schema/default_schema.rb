require 'psych/schema/core_schema'
require 'psych/schema/ruby_schema'
require 'psych/schema/object_schema'
require 'psych/schema/syck_schema'  # deprecated

module Psych
  # The default set of tags.
  DEFAULT_SCHEMA = CORE_SCHEMA + RUBY_SCHEMA + OBJECT_SCHEMA + SYCK_SCHEMA
end

