class Class
  def self.new_with(coder)
    name = coder.scalar
    name.split('::').inject(Object) { |k,n| k.const_get n }

    # NOTE: In Ruby 2.0+ this should work:
    #Object.const_get(coder.scalar)

    # NOTE: This is what was used before, but path2class is not
    # a Psych class method. It is in Schema. So unless it is 
    # moved this will not work. But it is probably not needed,
    # b/c the only thing it does differenly is lookup structs.
    #Psych.resolve_class(coder.scalar) 
  end
end

