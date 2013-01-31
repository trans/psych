class Struct
  def self.yaml_new(value)
    new(*h.map { |k,v| k.to_sym }).new(*h.map { |k,v| v })
  end
end
