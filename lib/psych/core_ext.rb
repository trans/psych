require 'psych/core_ext/object'
require 'psych/core_ext/array'
require 'psych/core_ext/hash'
require 'psych/core_ext/string'
require 'psych/core_ext/range'
require 'psych/core_ext/regexp'
require 'psych/core_ext/class'
require 'psych/core_ext/module'
require 'psych/core_ext/complex'
require 'psych/core_ext/rational'
require 'psych/core_ext/struct'

if defined?(::IRB)
  require 'psych/y'
end
