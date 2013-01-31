class Module
  def self.yaml_new(value)
    Psych.resolve_class(value) 
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

