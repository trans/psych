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

      #def accept target
      #  super
      #end

    private

      def deserialize o, kind=:scalar
        if kind == :scalar
          # Just becuase it is quoted doesn't mean it doesn't have a type, does it?
          #return register(o, o.value) if o.quoted
          return register(o, o.value) if o.quoted && !o.tag  # literal string
          return register(o, @ss.tokenize(o.value)) unless o.tag 
        end
        resolve_tag(o, kind)
      end

      def ruby_tag?(o)
        o.tag && o.tag.start_with?('!ruby/')
      end

      # Resolve a node based on its tag.
      #
      # Returns nil if there is no tag, or if there was no type assigned to the tag.
      def resolve_tag node, kind=:scalar
        tag, type = resolve_type(node, kind)

        case type
        when Class
          if type.method_defined?(:init_with) && type != Struct
            instance = register node, type.allocate
            coder = make_coder(node, kind, tag)
            instance.init_with(coder)
          elsif type.method_defined?(:yaml_initialize)  # deprecated behavior
            if $VERBOSE
              warn "Implementing #{node.class}#yaml_initialize is deprecated, please implement \"init_with(coder)\""
            end
            instance = register node, type.allocate
            coder = make_coder(node, kind, tag)
            instance.yaml_initialize(tag, coder.value)
            coder = make_coder(node, kind, tag)
            instance = register node, type.new_with(coder)
          end
        #when Proc  # Deprecated!
        #  instance = type.call(node.tag, node.value)  # or just (node) ?
        #  register node, instance
        else
          raise NameError, "unknown tag type #{tag}" if ruby_tag?(node)
          instance = @ss.tokenize(node.value)
          register node, instance
        end

        instance.yaml_tag = node.tag if instance

        instance
      end

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

      # Resolve value based on node kind.
      #
      # o    - YAML node.        [Psych::Nodes::Node]
      # kind - The kind of node. [Symbol]
      #
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

=begin
        #if klass = @schema.load_tags[o.tag]
        #  instance = klass.allocate
        #  
        #  if instance.respond_to?(:init_with)
        #    coder = Psych::Coder.new(o.tag)
        #    coder.seq = o.children.map { |c| accept c }
        #    instance.init_with coder
        #  end
        # 
        #  return instance
        #end

        case o.tag
        when nil
          register_empty(o)
        when '!omap', 'tag:yaml.org,2002:omap'
          map = register(o, Psych::Omap.new)
          o.children.each { |a|
            map[accept(a.children.first)] = accept a.children.last
          }
          map
        when /^!(?:seq|ruby\/array):(.*)$/
          klass = resolve_class($1)
          list  = register(o, klass.allocate)
          o.children.each { |c| list.push accept c }
          list
        else
          register_empty(o)
        end
      end

      def visit_Psych_Nodes_Mapping o
        return revive(@schema.load_tags[o.tag], o) if @schema.load_tags[o.tag]
        return revive_hash({}, o) unless o.tag

        case o.tag
        when /^!ruby\/struct:?(.*)?$/
          klass = resolve_class($1)

          if klass
            s = register(o, klass.allocate)

            members = {}
            struct_members = s.members.map { |x| x.to_sym }
            o.children.each_slice(2) do |k,v|
              member = accept(k)
              value  = accept(v)
              if struct_members.include?(member.to_sym)
                s.send("#{member}=", value)
              else
                members[member.to_s.sub(/^@/, '')] = value
              end
            end
            init_with(s, members, o)
          else
            members = o.children.map { |c| accept c }
            h = Hash[*members]
            Struct.new(*h.map { |k,v| k.to_sym }).new(*h.map { |k,v| v })
          end

        when /^!(?:str|ruby\/string)(?::(.*))?/, 'tag:yaml.org,2002:str'
          klass = resolve_class($1)
          members = Hash[*o.children.map { |c| accept c }]
          string = members.delete 'str'

          if klass
            string = klass.allocate.replace string
            register(o, string)
          end

          init_with(string, members.map { |k,v| [k.to_s.sub(/^@/, ''),v] }, o)


        when /^!ruby\/exception:?(.*)?$/
          h = Hash[*o.children.map { |c| accept c }]

          e = build_exception((resolve_class($1) || Exception),
                              h.delete('message'))
          init_with(e, h, o)


        when /^!map:(.*)$/, /^!ruby\/hash:(.*)$/
          revive_hash resolve_class($1).new, o

        when '!omap', 'tag:yaml.org,2002:omap'
          map = register(o, Psych::Omap.new)
          o.children.each_slice(2) do |l,r|
            map[accept(l)] = accept r
          end
          map

        else
          revive_hash({}, o)
        end
      end
=end

      #
      def register node, object
        @st[node.anchor] = object if node.anchor
        object
      end

      # The `<<` key is a merge key.
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

=begin
      def register_empty object
        list = register(object, [])
        object.children.each { |c| list.push accept c }
        list
      end


      def revive_hash hash, o
        @st[o.anchor] = hash if o.anchor

        o.children.each_slice(2) { |k,v|
          key = accept(k)
          val = accept(v)

          if key == '<<'
            case v
            when Nodes::Alias
              begin
                hash.merge! val
              rescue TypeError
                hash[key] = val
              end
            when Nodes::Sequence
              begin
                h = {}
                val.reverse_each do |value|
                  h.merge! value
                end
                hash.merge! h
              rescue TypeError
                hash[key] = val
              end
            else
              hash[key] = val
            end
          else
            hash[key] = val
          end

        }
        hash
      end

      def merge_key hash, key, val
      end


      def revive klass, node
        s = klass.allocate
        @st[node.anchor] = s if node.anchor
        h = Hash[*node.children.map { |c| accept c }]
        init_with(s, h, node)
      end
=end

      # Make Coder.
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
          # TODO: How is this possible?
          coder.object = resolve_value(node, kind)
        end
        coder
      end

    end

  end
end
