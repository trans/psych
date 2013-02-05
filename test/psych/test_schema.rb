require 'psych/helper'

module Psych
  class TestSchema < TestCase
    def setup
      #Psych.reset_schema!
    end

    def test_empty_schema_has_failsafe_tags
      schema = Psych::Schema.new
      assert_equal(3, schema.size)
    end

    def test_option_to_remove_failsafe_tags
      schema = Psych::Schema.new(:failsafe=>false)
      assert_equal(0, schema.size)
    end

    def test_adding_new_tags
      schema = Psych::Schema.new
      schema.tag "!foo", String
      assert_equal(4, schema.size)
    end

    def test_adding_via_block_is_lazy
      schema = Psych::Schema.new do |s|
        s.tag "!foo", String
      end
      assert_equal(3, schema.size)
      schema.resolve!
      assert_equal(4, schema.size)
    end

    def test_can_use_define_to_add_lazy_block
      schema = Psych::Schema.new
      schema.define do |s|
        s.tag "!foo", String
      end
      assert_equal(3, schema.size)
      schema.resolve!
      assert_equal(4, schema.size)
    end

    def test_calling_find_causes_resolve
      schema = Psych::Schema.new do |s|
        s.tag "!foo", String
      end
      assert_equal(3, schema.size)
      schema.find('!bar')
      assert_equal(4, schema.size)
    end

    def test_find_looks_up_matching_tag
      schema = Psych::Schema.new do |s|
        s.tag "!foo", String
      end
      tag, type = schema.find('!foo')
      assert_equal('!foo', tag)
      assert_equal(String, type)
    end

    def test_handles_prefix_directives
      prefix = { '!foo!' => 'tag:foo.org:' }
      schema = Psych::Schema.new(:prefix=>prefix) do |s|
        s.tag "!foo!bar", Integer
      end
      tag, type = schema.find('tag:foo.org:bar')
      assert_equal('tag:foo.org:bar', tag)
      assert_equal(Integer, type)     
    end

    def test_handles_intermediate_prefix_directives
      schema = Psych::Schema.new do |s|
        s.prefix '!bar!', 'tag:bar.org:'
        s.tag "!bar!foo", String
      end
      tag, type = schema.find('tag:bar.org:foo')
      assert_equal('tag:bar.org:foo', tag)
      assert_equal(String, type)     
    end

    def test_remove_tag
      schema = Psych::Schema.new do |s|
        s.tag "!foo", String
      end
      assert_equal(3, schema.size)
      schema.resolve!
      assert_equal(4, schema.size)
      schema.remove_tag('!foo')
      assert_equal(3, schema.size)
    end

  end
end
