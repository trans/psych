require 'psych/helper'

require 'stringio'
require 'tempfile'

class TestPsych < Psych::TestCase
  def teardown
    Psych.global_schema = Psych::DEFAULT_SCHEMA.dup
    #Psych.domain_types.clear
  end

  def test_line_width
    yml = Psych.dump('123456 7', { :line_width => 5 })
    assert_match(/^\s*7/, yml)
  end

  def test_indent
    yml = Psych.dump({:a => {'b' => 'c'}}, {:indentation => 5})
    assert_match(/^[ ]{5}b/, yml)
  end

  def test_canonical
    yml = Psych.dump({:a => {'b' => 'c'}}, {:canonical => true})
    assert_match(/\? ! "b/, yml)
  end

  def test_header
    yml = Psych.dump({:a => {'b' => 'c'}}, {:header => true})
    assert_match(/YAML/, yml)
  end

  def test_version_array
    yml = Psych.dump({:a => {'b' => 'c'}}, {:version => [1,1]})
    assert_match(/1.1/, yml)
  end

  def test_version_string
    yml = Psych.dump({:a => {'b' => 'c'}}, {:version => '1.1'})
    assert_match(/1.1/, yml)
  end

  def test_version_bool
    yml = Psych.dump({:a => {'b' => 'c'}}, {:version => true})
    assert_match(/1.1/, yml)
  end

  def test_load_argument_error
    assert_raises(TypeError) do
      Psych.load nil
    end
  end

  def test_non_existing_class_on_deserialize
    e = assert_raises(ArgumentError) do
      Psych.load("--- !ruby/object:NonExistent\nfoo: 1")
    end
    assert_includes e.message, 'NonExistent'
  end

  def test_dump_stream
    things = [22, "foo \n", {}]
    stream = Psych.dump_stream(*things)
    assert_equal things, Psych.load_stream(stream)
  end

  def test_dump_file
    hash = {'hello' => 'TGIF!'}
    Tempfile.open('fun.yml') do |io|
      assert_equal io, Psych.dump(hash, io)
      io.rewind
      assert_equal Psych.dump(hash), io.read
    end
  end

  def test_dump_io
    hash = {'hello' => 'TGIF!'}
    stringio = StringIO.new ''
    assert_equal stringio, Psych.dump(hash, stringio)
    assert_equal Psych.dump(hash), stringio.string
  end

  def test_simple
    assert_equal 'foo', Psych.load("--- foo\n")
  end

  def test_libyaml_version
    assert Psych.libyaml_version
    assert_equal Psych.libyaml_version.join('.'), Psych::LIBYAML_VERSION
  end

  def test_load_documents
    docs = Psych.load_documents("--- foo\n...\n--- bar\n...")
    assert_equal %w{ foo bar }, docs
  end

  def test_parse_stream
    docs = Psych.parse_stream("--- foo\n...\n--- bar\n...")
    assert_equal %w{ foo bar }, docs.children.map { |x| x.transform }
  end

  def test_add_builtin_type
    Psych.add_builtin_type 'omap' do |type|
      Class.new{ attr :a }
    end
    val = Psych.load("--- !!omap\n  a: hello")
    assert_equal 'hello', val.a
  ensure
    Psych.remove_type 'omap'
  end

  def test_add_domain_type_1
    klass = Class.new do
      def self.new_with(coder); coder.value; end
    end

    got = nil
    Psych.add_domain_type 'foo.bar,2002', 'foo' do |tag|
      got = tag
      klass
    end

    # Without the `tag:` this is just a local tag, not a domain tag.
    val = Psych.load('--- !<tag:foo.bar,2002/foo> hello')
    assert_equal 'tag:foo.bar,2002:foo', got
    assert_equal 'hello', val
  end

  def test_add_domain_type_2
    klass = Class.new do
      def self.new_with(coder); coder.value; end
    end

    got = nil
    Psych.add_domain_type 'foo.bar,2002', 'foo' do |tag|
      got = tag
      klass
    end

    # Without the `tag:` this is just a local tag, not a domain tag.
    val = Psych.load("--- !<tag:foo.bar,2002/foo>\n- hello\n- world")
    assert_equal 'tag:foo.bar,2002:foo', got
    assert_equal %w{ hello world }, val
  end

  def test_add_domain_type_3
    klass = Class.new do
      def self.new_with(coder); coder.value; end
    end

    got = nil
    Psych.add_domain_type 'foo.bar,2002', 'foo' do |tag|
      got = tag
      klass
    end

    val = Psych.load("--- !tag:foo.bar,2002/foo\nhello: world")
    assert_equal 'tag:foo.bar,2002:foo', got
    assert_equal({ 'hello' => 'world' }, val)
  end

  def test_load_file
    t = Tempfile.new(['yikes', 'yml'])
    t.binmode
    t.write('--- hello world')
    t.close
    assert_equal 'hello world', Psych.load_file(t.path)
    t.close(true)
  end

  def test_parse_file
    t = Tempfile.new(['yikes', 'yml'])
    t.binmode
    t.write('--- hello world')
    t.close
    assert_equal 'hello world', Psych.parse_file(t.path).transform
    t.close(true)
  end

  def test_degenerate_strings
    assert_equal false, Psych.load('    ')
    assert_equal false, Psych.parse('   ')
    assert_equal false, Psych.load('')
    assert_equal false, Psych.parse('')
  end

  def test_callbacks
    types = []
    appender = lambda { |tag| types << tag; Class.new(String) }

    Psych.add_builtin_type('foo', &appender)
    Psych.add_domain_type('example.com,2002', 'foo', &appender)
    Psych.load <<-eoyml
- !<tag:yaml.org,2002:foo> bar
- !<tag:example.com,2002:foo> bar
    eoyml

    assert_equal [
      "tag:yaml.org,2002:foo",
      "tag:example.com,2002:foo"
    ], types
  end
end
