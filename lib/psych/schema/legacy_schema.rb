require 'psych/schema/core_schema'
require 'psych/schema/failsafe_schema'
require 'psych/schema/json_schema'
require 'psych/schema/ruby_schema'
require 'psych/schema/object_schema'
require 'psych/schema/syck_schema'  # deprecate

module Psych
  LEGACY_SCHEMA = CORE_SCHEMA + RUBY_SCHEMA + OBJECT_SCHEMA + SYCK_SCHEMA
end

