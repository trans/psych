require 'psych/schema/failsafe_schema'
require 'psych/schema/json_schema'

module Psych
  # The set of core YAML tags.
  CORE_SCHEMA = FAILSAFE_SCHEMA + JSON_SCHEMA
end
