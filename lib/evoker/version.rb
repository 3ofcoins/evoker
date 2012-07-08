module Evoker
  # Version information
  module VERSION
    # Major version number
    MAJOR = 0

    # Minor version number
    MINOR = 0

    # Tiny version number
    TINY  = 10

    # Full version number as string
    STRING = [MAJOR, MINOR, TINY].join('.')

    # Raise an error if Evoker version is older than required.
    def VERSION.require_version(major, minor=0, tiny=0)
      unless ([MAJOR, MINOR, TINY] <=> [major, minor, tiny]) >= 0
        raise "Evoker version #{MAJOR}.#{MINOR}.#{TINY} is below required #{major}.#{minor}.#{tiny}"
      end
    end
  end
end
