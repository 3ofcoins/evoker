# Caching of individual downloaded files in a local directory

require 'digest'
require 'fileutils'

require 'evoker'
require 'rake/clean'

module Evoker
  smart_const(:cache_path, 'cache')

  module_function

  # Cache result of a file task in local directory.
  #
  # If cached `output_file` exists and matches the checksum (if one is
  # given), task to copy file from cache directory to target is
  # returned, and block is not executed.
  # 
  # If cached `output_file` exists but does not match the checksum, it is
  # removed.
  # 
  # If `output file` does not exist or did not match the checksum,
  # block is executed. Block should return a file task. This task will
  # have extra code appended:
  # 
  # - a checksum test: if checksum is given - error is raised if
  #   created file does not match the checksum
  # - copying created file to cache directory
  # 
  # Cache directory is taken from a smart constant (see
  # {#smart_const_get}) `:cache_path`, default is 'cache'.
  # 
  # @param [String] output_file File to uncache or create
  # @param [String] checksum SHA-256 checksum of file (optional, but recommended)
  # @yield Task to create file if not found in cache
  # @return Task to uncache or create file
  def cached(output_file, checksum=nil)
    raise 'Block for Evoker::cached not provided' unless block_given?

    cached_path_elts = []
    cached_path_elts << smart_const_get(:cache_path)
    cached_path_elts << checksum[0..1] if checksum
    cached_path_elts << checksum[2..3] if checksum
    cached_path_elts << File.basename(output_file)
    cached_path = File.join(*cached_path_elts)

    if File.exists?(cached_path) &&
        checksum &&
        Digest::SHA256.file(cached_path).hexdigest != checksum
      puts "WARN: checksum mismatch for cached #{File.basename(output_file)}, removing."
      FileUtils::rm cached_path
    end

    if File.exists?(cached_path)
      # Cached file exists and matches the given checksum
      rv = file output_file do
        FileUtils::cp cached_path, output_file
      end
    else
      # Cached file does not exist
      rv = yield output_file

      # Cache file after downloading
      task rv do
        if checksum &&
            Digest::SHA256.file(output_file).hexdigest != checksum
          raise "Checksum mismatch for downloaded #{File.basename(output_file)}."
        end
        FileUtils::mkdir_p(File.dirname(cached_path))
        FileUtils::cp output_file, cached_path
      end
    end

    CLEAN << output_file
    CLOBBER << cached_path

    rv
  end


  # Download a file using wget, or copy it from local cache
  # 
  # @param [#to_s] url address to download from
  # @param [Hash] opts options (same as wget, + :checksum)
  # @option opts [#to_s] :checksum sha256 sum of file to download
  def cached_wget(url, opts={})
    opts[:output_file] ||= begin
                             require 'uri'
                             URI.parse(url).path.split('/').last
                           end

    cached(opts[:output_file], opts[:checksum]) do
      wget url, opts
    end
  end
end
