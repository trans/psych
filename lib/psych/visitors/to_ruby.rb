require 'psych/scalar_scanner'

unless defined?(Regexp::NOENCODING)
  Regexp::NOENCODING = 32
end

module Psych
  module Visitors
    ###
    # This class walks a YAML AST, converting each node to ruby
    class ToRuby < Psych::Visitors::Visitor
      # Initialize new ToRuby instance.
      #
      # Options
      #
      #   :schema - Schema instance.
      #   :ss     - Scalar scanner.
      #
      def initialize options={}
        super()
        @st = {}
        @ss = options[:ss] || ScalarScanner.new
        @schema = options[:schema] || Psych.global_schema
        @schema.resolve!
      end

      def visit_Psych_Nodes_Scalar o
        deserialize(o, :scalar)
      end

      def visit_Psych_Nodes_Sequence o
        deserialize(o, :seq)
      end

      def visit_Psych_Nodes_Mapping o
        deserialize(o, :map)
      end

      def visit_Psych_Nodes_Document o
        accept o.root
      end

      def visit_Psych_Nodes_Stream o
        o.children.map { |c| accept c }
      end

      def visit_Psych_Nodes_Alias o
        @st.fetch(o.anchor) { raise BadAlias, "Unknown alias: #{o.anchor}" }
      end

    private

      ##
      # Is a tag a Ruby tag? A Ruby tag is recognized by a specific local tag
      # prefix, `!ruby/`.
      # `
      # TODO: Probably this should be a globally unique domain tag instead.
      #
      # Returns true if so, false otherwise. [Boolean]
      def ruby_tag?(o)
        o.tag && o.tag.start_with?('!ruby/')
      end

      ###
      # Deserialize object represented by the given node.
      #
      # node - Psych node. [Psych::Nodes::Node]
      # kind - The kind of node. [:scalar,:map,:seq]
      #
      # Returns deserialize object. [Object]
      def deserialize node, kind=:scalar
        if kind == :scalar
          # Just becuase it is quoted doesn't mean it doesn't have a type, does it?
          #return register(node, node.value) if node.quoted
          return register(node, node.value) if node.quoted && !node.tag  # literal string
          return register(node, @ss.tokenize(node.value)) unless node.tag 
        end
        resolve_tag(node, kind)
      end

      ###
      # Resolve a node based on its tag.
      #
      # Returns nil if there is no tag, or if there was no type assigned to the tag.
      def resolve_tag node, kind=:scalar
        tag, type = resolve_type(node, kind)

        case type
        when Class, Module  # modules are for factories
          if type.singleton_class.method_defined?(:new_with)
            coder = make_coder(node, kind, tag)
            instance = register(node, type.new_with(coder))
          else
            begin
              object = type.allocate
            rescue TypeError
              raise TypeError, "cannot allocate #{type}. Add #{type}.new_with method."
            else            
              instance = register node, object
              coder = make_coder(node, kind, tag)

              if type.method_defined?(:init_with)
                instance.init_with(coder)
              elsif type.method_defined?(:yaml_initialize) # deprecated behavior
                warn "Implementing #{node.class}#yaml_initialize is deprecated, please implement \"init_with(coder)\"" if $VERBOSE
                instance.yaml_initialize(tag, coder.value)
              else
                general_init_with(instance, coder)
              end
            end
          end
        else
          raise NameError, "unknown tag type #{tag}" if ruby_tag?(node)
          instance = @ss.tokenize(node.value)
          register node, instance
        end

        instance.tag_uri = node.tag if instance

        instance
      end

      ###
      # The fallback "init_with", when #init_with is not defined.
      #
      # instance - The allocated instance of the tag class. [Object]
      # coder    - Prepared coder. [Psych::Coder]
      #
      # Returns nothing.
      def general_init_with(instance, coder)
        case coder.type
        when :map
          coder.map.each do |k,v|
            k = "@#{k}" unless k.to_s.start_with?('@')
            instance.instance_variable_set(k, v)
          end
        else
          if coder.value
            #raise TypeError, "#{instance.class} is not a #{coder.type}."
            warn "#{instance.class} is not a #{coder.type}, value discarded -- `#{coder.value}'" if $VERBOSE
          end 
        end
      end

      ###
      # Resolve the tag's type, that is to say, its class.
      #
      # o    - YAML node.        [Psych::Nodes::Node]
      # kind - The kind of node. [Symbol]
      #
      # Returns type. [Class,nil]
      def resolve_type(o, kind)
        if o.tag
          tag, type = @schema.find(o.tag)
        end

        unless type
          tag  = o.tag
          type = {:scalar=>nil, :seq=>Array, :map=>Hash}[kind]
        end

        return tag, type
      end

      ###
      # Resolve value based on node kind.
      #
      # o    - YAML node.        [Psych::Nodes::Node]
      # kind - The kind of node. [Symbol]
      #
      # Returns the resolved value. [Object]
      def resolve_value(o, kind)
        case kind
        when :scalar
          value = o.tag ? o.value : @ss.tokenize(o.value)
        when :seq
          value = o.children.map { |c| accept c }
        when :map
          hash = {}
          o.children.each_slice(2) do |k,v|
            key = accept(k)
            val = accept(v)
            if key == '<<'
              merge_key(hash, v, key, val)
            else
              hash[key] = val
            end
          end
          value = hash
        end
        value
      end

      ###
      # Register object, adding it to the alias table.
      #
      # node   - The node. [Psych::Nodes::Node]
      # object - The object being created. [Object]
      #
      # Returns object. [Object]
      def register node, object
        @st[node.anchor] = object if node.anchor
        object
      end

      ###
      # The `<<` key is a merge key.
      #
      # hash  - The hash accepting the merge. [Hash]
      # node  - The node. [Psych::Nodes::Node]
      # key   - The merge key, always `<<`. ["<<"]
      # value - The hash to merge. [Hash]
      #
      # Returns nothing.
      def merge_key(hash, node, key, value)
        case node
        when Nodes::Alias
          begin
            hash.merge! value
          rescue TypeError
            hash[key] = value
          end
        when Nodes::Sequence
          begin
            h = {}
            value.reverse_each{ |v| h.merge! v }
            hash.merge! h
          rescue TypeError
            hash[key] = value
          end
        else
          hash[key] = value
        end
      end

      ###
      # Make Coder ot use for constructor/initializer.
      #
      # node - Psych node. [Psych::Nodes::Node]
      # kind - The kind of node. [Symbol]
      # tag  - Tag used be YAML document. [String]
      #
      # Note: The tag argument is only needed for legacy tags, which
      # can match different document tags for one defined tag. This
      # can probably be deprecated sometime in the future.
      #
      # Returns a prepared coder. [Psych::Coder]
      def make_coder(node, kind, tag)
        coder = Psych::Coder.new(tag, @ss) #node.tag, @ss)
        case kind
        when :scalar
          coder.scalar = resolve_value(node, kind)
        when :map
          coder.map = resolve_value(node, kind)
        when :seq
          coder.seq = resolve_value(node, kind)
        else
          # TODO: How is this even possible? Why does coder.object exist?
          coder.object = resolve_value(node, kind)
        end
        coder
      end

    end

  end
end
