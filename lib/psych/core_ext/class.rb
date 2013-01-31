class Class
  def self.yaml_new(value)
    Psych.resolve_class(value) 
  end
end

