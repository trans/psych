class Struct
  def self.new_with(coder)
    value = coder.map
    new(*value.map { |k,v| k.to_sym }).new(*value.map { |k,v| v })
  end

  def init_with(coder)
    coder.map.each do |m, v|
      #if members.map{ |b| b.to_sym }.include?(m.to_sym)
      if members.include?(m.to_sym)
        send("#{m}=", v)
      else
        # TODO: Isn't this an error?
        #members[m.to_s.sub(/^@/, '')] = v
      end
    end
  end
end

