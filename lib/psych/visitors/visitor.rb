module Psych
  module Visitors
    class Visitor
      def accept target
        visit target
      end

      private

      DISPATCH = Hash.new do |hash, klass|
        hash[klass] = "visit_#{klass.name.gsub('::', '_')}"
      end

      def visit target
        msg = DISPATCH[target.class]

        send msg, target
      end
    end
  end
end
