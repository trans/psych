module Psych
  class Omap < ::Hash
    def init_with(coder)
      case coder.type
      when :seq
        coder.seq.each{ |h| update(h) }
      else
        replace coder.map
      end
    end
  end
end
