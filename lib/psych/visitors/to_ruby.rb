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
        @schema = options[:schema] || DEFAULT_SCHEMA
      end

      def visit_Psych_Nodes_Scalar o
        deserialize(o, :scalar)
      end

      def visit_Psych_Nodes_Sequence o
        deserialize(o, :sequence)
      end

      def visit_Psych_Nodes_Mapping o
        deserialize(o, :mapping)
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

      # @deprecated Forget those global domain type. So just use super method.
      def accept target
        result = super
        #return result if @schema.domain_types.empty? || !target.tag

        #key = target.tag.sub(/^[!\/]*/, '').sub(/(,\d+)\//, '\1:')
        #key = "tag:#{key}" unless key =~ /^(tag:|x-private)/

        #if @schema.domain_types.key? key
        #  value, block = @schema.domain_types[key]
        #  return block.call value, result
        #end

        result
      end

    private

      def deserialize o, kind=:scalar
        ## NOTE: This seems like a whacky way to handle things
        ##       is this for a special set of classes of something ?
        #if klass = @schema.load_tags[o.tag]
        #  instance = klass.allocate
        #
        #  if instance.respond_to?(:init_with)
        #    coder = Psych::Coder.new(o.tag)
        #    coder.scalar = o.value
        #    instance.init_with coder
        #  end
        #
        #  return instance
        #end

        # just becuase it is quoted doesn't mean it doesn't have a type!
        #return o.value if o.quoted  # literal string

        resolve_tag(o, kind)
      end

      # Resolve a node based on its tag.
      #
      # Returns nil if there is no tag, or if there was not type assigned to the tag.
      def resolve_tag o, kind=:scalar
        if o.tag
          tag, type = @schema.tags[kind].find do |t, _|
            t === o.tag
          end
        else
          type = {:scalar=>nil, :sequence=>Array, :mapping=>Hash}[kind]
        end

        # TODO: Okay ?
        if Proc === type
          type = type.call(o.tag, o.value)
          raise ArgumentError unless Class == type
        end

        case type
        when Class
          if type.instance_method(:yaml_initialize)
            instance = register o, type.allocate
            value = resolve_value(o, kind)
            instance.yaml_initialize(value)
          else
            value = resolve_value(o, kind)
            instance = type.yaml_new(value)
          end
        #when Proc  # TODO: do we really want this at all ?
        #  instance = type.call(o.tag, o.value)  # or just (o) ?
        #  register o, instance
        else
          instance = @ss.tokenize(o.value)
          register o, instance
        end

        instance.yaml_tag = o.tag if instance && o.tag

        instance
      end

      # Resolve value based on node kind.
      def resolve_value(o, kind)
        case kind
        when :scalar
          value = o.tag ? o.value : @ss.tokenize(o.value)
        when :sequence
          value = o.children.map { |c| accept c }
        when :mapping
          value = {}
          o.children.each_slice(2) do |k,v|
            key = accept(k)
            val = accept(v)
            if key == '<<'
              merge_key(value, val)
            else
              value[key] = accept(val)
            end
          end
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
      def merge_key(hash, node, node_value)
        case node
        when Nodes::Alias
          begin
            hash.merge! node_value
          rescue TypeError
            hash[key] = node_value
          end
        when Nodes::Sequence
          begin
            h = {}
            node_value.reverse_each{ |v| h.merge! v }
            hash.merge! h
          rescue TypeError
            hash[key] = node_value
          end
        else
          hash[key] = node_value
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

=begin
      def init_with o, h, node
        c = Psych::Coder.new(node.tag)
        c.map = h

        if o.respond_to?(:init_with)
          o.init_with c
        elsif o.respond_to?(:yaml_initialize)
          if $VERBOSE
            warn "Implementing #{o.class}#yaml_initialize is deprecated, please implement \"init_with(coder)\""
          end
          o.yaml_initialize c.tag, c.map
        else
          h.each { |k,v| o.instance_variable_set(:"@#{k}", v) }
        end
        o
      end
=end

      # Convert +klassname+ to a Class
      def resolve_class klassname
        return nil unless klassname and not klassname.empty?

        name    = klassname
        retried = false

        begin
          path2class(name)
        rescue ArgumentError, NameError => ex
          unless retried
            name    = "Struct::#{name}"
            retried = ex
            retry
          end
          raise retried
        end
      end
    end
  end
end
