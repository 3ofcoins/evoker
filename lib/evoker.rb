$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rake'
require 'rake/clean'

require 'evoker/version'

# Evoker is a tool to manage external dependencies of a project using
# Rake to run downloads.
module Evoker
  class EntityTask < Rake::FileTask
    attr_reader :config

    def initialize(*args, &block)
      super(*args, &block)
      @stampname = "#{@name}.stamp"
      @actions << lambda { rm_rf @name }
      CLOBBER.add([@stampname, @name])

      if File.exists? "#{@name}.yaml"
        @config = YAML::load_file("#{@name}.yaml")
        self.enhance [Rake.application.intern(Rake::FileTask, "#{@name}.yaml")]
      end
    end

    def execute(args=nil)
      super
      File.open(@stampname, 'w') { |f| f.write(DateTime::now.to_s) }
    end

    ## copy-paste from FileTask to use @stampname instead of name
    def needed?
      ! File.exist?(name) || ! File.exist?(@stampname) || out_of_date?(timestamp)
    end

    # Time stamp for file task.
    def timestamp
      if File.exist?(@stampname)
        File.mtime(@stampname)
      else
        Rake::EARLY
      end
    end
  end

  class << self
    def entity(*args, &block)
      Evoker::EntityTask.define_task(*args, &block)
    end
  end
end

