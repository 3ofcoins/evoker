# Caching of individual downloaded files in a local directory

require 'digest'
require 'fileutils'

require 'evoker'
require 'rake/clean'

module Evoker
  smart_const(:cache_path, 'cache')

  module_function

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

    cached_path_elts = []
    cached_path_elts << smart_const_get(:cache_path)
    cached_path_elts << opts[:checksum][0..1] if opts[:checksum]
    cached_path_elts << opts[:checksum][2..3] if opts[:checksum]
    cached_path_elts << File.basename(opts[:output_file])
    cached_path = File.join(*cached_path_elts)

    if File.exists?(cached_path)
      if opts[:checksum] &&
          Digest::SHA256.file(cached_path).hexdigest != opts[:checksum]
        puts "WARN: checksum mismatch for cached #{File.basename(opts[:output_file])}, removing."
        FileUtils::rm cached_path
      else
        # no checksum or checksum match, we can proceed
        file opts[:output_file] do
          FileUtils::cp cached_path, opts[:output_file]
        end
      end
    else
      wget url, opts
      # add caching after downloading
      task opts[:output_file] do
        if opts[:checksum] &&
            Digest::SHA256.file(opts[:output_file]).hexdigest != opts[:checksum]
          raise "Checksum mismatch for downloaded #{File.basename(opts[:output_file])}."
        end
        FileUtils::mkdir_p(File.dirname(cached_path))
        FileUtils::cp opts[:output_file], cached_path
      end
    end
    CLEAN << opts[:output_file]
    CLOBBER << cached_path

    file opts[:output_file]
  end
end
