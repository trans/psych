class Range
  # Deserialize YAML representation into Range.
  # 
  # Note the original code resoved the sentinals as YAML scalars,
  # but that seems uncessary b/c Ranges are purely a Ruby convention.
  #
  def self.yaml_new(value)
    case value
    when String
      args = value.split(/([.]{2,3})/, 2)
      args.push(args.delete_at(1) == '...')
      Range.new(*args)
    when Array
      new(*array)
    when Hash
      new(value['begin'], value['end'], value['excl'])
    end
  end
end

