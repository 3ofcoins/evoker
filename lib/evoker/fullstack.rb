require 'evoker'
require 'evoker/local_cache'

module Evoker
  module FullStack
    Context = Struct.new( :tarball_filename, :tarball_path, :tarball_extension,
                          :source_dir_basename, :source_dir,
                          :download, :unpack ) do
      include Rake::DSL
      def source_file(subpath)
        File.join(self.source_dir, subpath)
      end
    end
  end

  smart_const(:build_path, 'build')
  smart_const(:download_path, 'download')

  module_function

  # Download tarball from given URL and unpack it for build.
  # 
  # A file from address `tarball_url` is downloaded (via
  # {#cached_wget}) to directory specified in the `:download_path`
  # smart constant, and then unpacked in directory specified in the
  # `:build_path` smart constant.
  # 
  # The block is called in context that defines following methods:
  # - `tarball_filename`
  # - `tarball_path`
  # - `tarball_extension` (e.g. `".tar.gz"`)
  # - `source_dir_basename`
  # - `source_dir`
  # - `download` (a Rake task that downloads the tarball)
  # - `unpack` (a Rake task that unpacks the tarball).
  #
  # Block should define a task or chain of tasks, that compile (and
  # possibly install, depending on needs) module contained in the
  # tarball. First of the tasks should depend on `unpack`, and last
  # should be returned from the block.
  #
  # Task named `task_name` that depends on the task returned from the
  # block will be created.
  # 
  # @example
  #   from_tarball :carbon, CARBON_URL do
  #     file installed('bin/carbon-aggregator.py') => [ PIP, :py2cairo ] do
  #       rm_f source_file('setup.cfg')
  #       pip_install source_dir
  #     end
  #   end
  def from_tarball(task_name, tarball_url, args={}, &block)
    task task_name

    build_path = File.expand_path(smart_const_get(:build_path))
    download_path = File.expand_path(smart_const_get(:download_path))

    mkdir_p build_path unless File.directory?(build_path)
    mkdir_p download_path unless File.directory?(download_path)

    tarball_filename = args[:filename] || File.basename(tarball_url)
    tarball_path = File.join(download_path, tarball_filename)
    tarball_extension = args[:extension] ||
      ( tarball_filename =~ /\.(tar(\.(Z|gz|bz2))?|zip)$/ ? $& : nil )
    source_dir_basename = args[:directory] ||
      File.basename(tarball_filename, tarball_extension)
    source_dir = File.join(build_path, source_dir_basename)
    unpack_command = args[:unpack] || {
      '.tar.gz' => 'tar -xzf',
      '.tar.bz2' => 'tar -xjf',
      '.tar.Z' => 'tar -xzf',
      '.tar' => 'tar -xf',
      '.zip' => 'unzip' }[tarball_extension.downcase]

    download = cached_wget(
      tarball_url, args.merge(:output_file => tarball_path))
     
    unpack = file source_dir => download do
      chdir smart_const_get(:build_path) do
        rm_rf source_dir_basename
        sh "#{unpack_command} #{tarball_path}"
      end
    end
    
    ctx = FullStack::Context.new(
      tarball_filename, tarball_path, tarball_extension,
      source_dir_basename, source_dir,
      download, unpack)

    final_file = ctx.instance_eval(&block)

    task final_file => unpack
    task task_name => final_file
  end

  def download(url, args={})
    args[:output_file] ||= File.expand_path(File.join(
        smart_const_get(:download_path),
        args[:filename] || File.basename(url)))
    cached_wget(url, args)
  end

  def dl(filename)
    File.join(smart_const_get(:download_path), filename)
  end
end
