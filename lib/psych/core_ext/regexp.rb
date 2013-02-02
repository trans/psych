class Regexp
  def self.new_with(coder)
    value = coder.scalar
    value =~ /^\/(.*)\/([mixn]*)$/
    source  = $1
    options = 0
    lang    = nil
    ($2 || '').split('').each do |option|
      case option
      when 'x' then options |= Regexp::EXTENDED
      when 'i' then options |= Regexp::IGNORECASE
      when 'm' then options |= Regexp::MULTILINE
      when 'n' then options |= Regexp::NOENCODING
      else lang = option
      end
    end
    new(*[source, options, lang].compact)
  end
end
