# @author Maciej Pasternacki <maciej@pasternacki.net>

$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) ||
  $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'date'

require 'rake'
require 'rake/clean'

require 'evoker/version'

# Evoker is a tool to manage external dependencies of a project using
# Rake to run downloads.
module Evoker
  extend Rake::DSL

  # {Rake::FileList} of defined entities
  # @example can be used as dependency for the default target
  #   task :default => Evoker::ENTITIES
  ENTITIES = Rake::FileList[]

  class EntityTask < Rake::FileTask
    ##
    # Parsed yaml config for the task
    attr_reader :config

    def initialize(*args, &block)
      super(*args, &block)
      @stampname = "#{@name}.stamp"
      @actions << lambda { |*args| rm_rf @name }
      CLOBBER.add([@stampname, @name])
      ENTITIES.add(@name)

      if File.exists? "#{@name}.yaml"
        require 'yaml'
        @config = YAML::load_file("#{@name}.yaml")
        self.enhance [Rake.application.intern(Rake::FileTask, "#{@name}.yaml")]
      end
    end

    # Executes task and writes its timestamp file
    def execute(args=nil)
      super
      File.open(@stampname, 'w') { |f| f.write(DateTime::now.to_s) }
    end

    # Use @stampname instead of task name to determine whether to re-do the task
    def needed?
      ! File.exist?(name) || ! File.exist?(@stampname) || out_of_date?(timestamp)
    end

    # Time stamp for file task is on the stamp file, not on target.
    def timestamp
      if File.exist?(@stampname)
        File.mtime(@stampname)
      else
        Rake::EARLY
      end
    end
  end

  # Base entity definition (wrapper over {EntityTask})
  # 
  # @param [#to_s] name name of task and directory
  # @param *args arguments for {EntityTask#initialize}
  # @yield [Rake::Task] block executed to populate target directory
  # @return [EntityTask] defined task
  def entity(name, *args, &block)
    Evoker::EntityTask.define_task(name, *args, &block)
  end
  module_function :entity

  # Download a file using wget.
  # 
  # @param [#to_s] url address to download from
  # @param [Hash] opts options
  # @option opts [#to_s] :output_file (basename of `url`) name of target file
  # @option opts [#to_s] :wget ('wget') wget command to use
  # @option opts [#to_s] :args (nil) custom command line arguments for wget
  # @option opts [True, False] :no_entity (false)
  #   do not add task to {Evoker::ENTITIES}
  def wget(url, opts={})
    opts[:output_file] ||= begin
                             require 'uri'
                             URI.parse(url).path.split('/').last
                           end
    opts[:wget] ||= 'wget'

    wget_command = "#{opts[:wget]} -O #{opts[:output_file]}"
    wget_command << " #{opts[:args]}" if opts[:args]
    wget_command << " #{url} && touch #{opts[:output_file]}"

    CLOBBER.add(opts[:output_file])
    ENTITIES.add(opts[:output_file]) unless opts[:no_entity]

    desc "Download #{url} as #{opts[:output_file]}"
    file opts[:output_file] do
      sh wget_command
      touch opts[:output_file]
    end
  end
  module_function :wget

  # Check out Subversion repository
  def subversion(name, opts={})
    opts[:svn] ||= "svn"
    entity name do |t|
      cmd = "#{opts[:svn]}"
      cmd << " #{opts[:svn_args]}" if opts[:svn_args]
      cmd << " #{t.config[:svn_args]}" if t.config[:svn_args]
      cmd << " checkout -q"
      cmd << " #{opts[:checkout_args]}" if opts[:checkout_args]
      cmd << " #{t.config[:checkout_args]}" if t.config[:checkout_args]
      cmd << " -r #{opts[:revision]}" if opts[:revision]
      cmd << " -r #{t.config[:revision]}" if t.config[:revision]
      cmd << " #{opts[:url]}" if opts[:url]
      cmd << " #{t.config[:url]}" if t.config[:url]
      cmd << " #{t.name}"
      sh cmd
    end
  end
  module_function :subversion

  # Check out Git repository
  def git(name, opts={})
    opts[:git] ||= "git"
    entity name do |t|
      cmd = "#{opts[:git]} clone"
      cmd << " #{opts[:clone_args]}" if opts[:clone_args]
      cmd << " #{t.config[:clone_args]}" if t.config[:clone_args]
      cmd << " #{opts[:url]}" if opts[:url]
      cmd << " #{t.config[:url]}" if t.config[:url]
      cmd << " #{t.name}"

      if rev = opts[:revision] || t.config[:revision]
        cmd << " && cd #{t.name}" \
          " && #{opts[:git]} checkout -b evoker-checkout #{rev}"
      end
      sh cmd
    end
  end
  module_function :git

  private

  # Define smart constant's default
  # @param name [#to_s] constant's name (will be upcased)
  # @param default constant's default value
  def self.smart_const(name, default)
    @@SMART_CONST_DEFAULTS ||= {}
    @@SMART_CONST_DEFAULTS[name.to_s.upcase] = default
  end

  # Get smart constant's effective value
  # 
  # Effective value is:
  # 1. `ENV[name.to_s.upcase]` if present
  # 2. Otherwise, user-defined top-level constant named `name.to_s.upcase`
  # 3. Otherwise, default set with {smart_const}
  # 4. Otherwise, nil
  # 
  # @param name [#to_s] constant's name
  def smart_const_get(name)
    name = name.to_s.upcase
    if ENV.has_key?(name)
      ENV[name]
    elsif Object.const_defined?(name)
      Object.const_get(name)      
    else
      @@SMART_CONST_DEFAULTS ||= {}
      @@SMART_CONST_DEFAULTS[name]
    end
  end
  module_function :smart_const_get
end
