class Struct
  # FIXME: This feels all sort of hackish. But the problem is that
  #        subclasses of Struct should use #init_with b/c they
  #        can use allocate, but Struct itself cannot.
#  def self.inherited(subclass)
#    subclass.singleton_class.send(:undef_method, :new_with)
#  end

  #
  module Factory
    def self.new_with(coder)
      value = coder.map
      Struct.new(*value.map { |k,v| k.to_sym }).new(*value.map { |k,v| v })
    end
  end

  def init_with(coder)
    coder.map.each do |m, v|
      if members.include?(m.to_sym)
        send("#{m}=", v)
      else
        iv = m.to_s.start_with?('@') ? m : "@#{m}"
        instance_variable_set(iv, v)
      end
    end
  end
end

