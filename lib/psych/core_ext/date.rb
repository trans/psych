require 'date'

class DateTime
  # TODO: Move to date.rb
  def self.new_with(coder)
    coder.scanner.parse_time(coder.scalar).to_datetime
  end
end
