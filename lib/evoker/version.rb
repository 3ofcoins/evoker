module Evoker
  module VERSION
    MAJOR = 0
    MINOR = 0
    TINY  = 8
    STRING = [MAJOR, MINOR, TINY].join('.')

    def VERSION.require_version(major, minor=0, tiny=0)
      unless ([MAJOR, MINOR, TINY] <=> [major, minor, tiny]) >= 0
        raise "Evoker version #{MAJOR}.#{MINOR}.#{TINY} is below required #{major}.#{minor}.#{tiny}"
      end
    end
  end
end
