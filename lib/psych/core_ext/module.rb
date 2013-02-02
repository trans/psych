class Module
  # See Class.new_with for details.
  def self.new_with(coder)
    name = coder.scalar
    name.split('::').inject(Object) { |k,n| k.const_get n }
  end

  def psych_yaml_as url
    return if caller[0].end_with?('rubytypes.rb')
    if $VERBOSE
      warn "#{caller[0]}: yaml_as is deprecated, please use yaml_tag"
    end
    Psych.add_tag(url, self)
  end

  remove_method :yaml_as rescue nil
  alias :yaml_as :psych_yaml_as
end

