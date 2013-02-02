class Hash
  def init_with(coder)
    replace coder.map
    # TODO: attributes
  end

  # Preserve order and reverse precendece.
  #
  def reverse_merge(other)
    other.each do |k,v|
      self[k] = v unless key?(k)
    end
  end
end

