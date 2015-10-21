module BigbluebuttonRails
  class DialNumber

    # Generates a random dial number based on the `pattern` (e.g. '123x-xxxx')
    def self.randomize(pattern=nil, opt={})
      return nil if pattern.nil?
      sym = get_symbol(opt)
      size = pattern.count(sym)

      # e.g. random from 0 to 999 if the pattern has 3 x's
      num = SecureRandom.random_number((10 ** size) - 1)

      get_dial_number_from_ordinal(num, pattern, opt)
    end

    def self.get_dial_number_from_ordinal(ordinal, pattern=nil, opt={})
      return nil if pattern.nil?
      sym = get_symbol(opt)

      number_size = pattern.count(sym)
      ordinal_str = ordinal.to_s.rjust(number_size,'0').reverse
      dial_number = pattern.reverse

      ordinal_str.each_char do |n|
        dial_number.sub!(sym, n)
      end

      dial_number.reverse
    end

    def self.get_ordinal_from_dial_number(number, pattern=nil, opt={})
      return nil if pattern.nil?
      sym = get_symbol(opt)

      regexp = Regexp.new(pattern.gsub(sym, '([0-9])')) # make a pattern to capture only the numbers
      match = regexp.match(number) # extract only the numbers

      # join the numbers and turn then into an ordinal integer
      ordinal = match[1, match.size].join.to_i if match.present?

      ordinal
    end

    def self.get_symbol opt
      opt[:symbol] || 'x'
    end
  end
end
