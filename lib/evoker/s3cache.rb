# Caching of downloaded upstream stuff as a tarball in an S3 bucket.

require 'evoker'
require 'fog'
require 'archive/tar/minitar'
require 'rake/clean'
require 'zlib'

module Evoker
  def _get_bucket
    $s3 ||= Fog::Storage.new(
      :provider => "AWS",
      :aws_access_key_id => CACHE_S3_ACCESS_KEY_ID,
      :aws_secret_access_key => CACHE_S3_SECRET_ACCESS_KEY,
      :persistent => false)
    $bucket ||= $s3.directories.get(CACHE_S3_BUCKET)
  end

  # hack to add cached tarballs to clobber before we know cache basename
  task :_s3cache_clobber_tarball do
    CLOBBER.add("#{CACHE_BASENAME}*.tgz")
  end
  task :clobber => :_s3cache_clobber_tarball

  namespace :s3cache do
    desc "Pack current directory and store resulting tarball in an S3 bucket"
    task :upload do
      bucket = _get_bucket

      if tarball = bucket.files.get(CACHE_TARBALL)
        if ENV['FORCE']
          puts "INFO: deleting file #{CACHE_TARBALL} from bucket because FORCE"
          tarball.destroy
          bucket.reload
        else
          raise "ERROR: file #{CACHE_TARBALL} already in the bucket."
        end
      end
      puts "INFO: archiving #{CACHE_TARBALL}"
      tgz = Zlib::GzipWriter.new(File.open(CACHE_TARBALL, 'wb'))
      Archive::Tar::Minitar.pack(
        Dir.entries('.').reject { |fn|
          fn == '.' or fn == '..' or
            fn =~ /#{Regexp.quote(CACHE_BASENAME)}.*\.tgz$/ },
        tgz)
      puts "INFO: uploading #{CACHE_TARBALL} to #{CACHE_S3_BUCKET}"

      # retry upload 3 times
      _tries = 0
      begin
        File.open(CACHE_TARBALL, 'r') do |tarball|
          bucket.files.create(
            :key => CACHE_TARBALL,
            :body => tarball)
        end
      rescue
        _tries += 1
        if _tries <= 3
          puts "WARN: retrying #{_tries}/3: #{$!}"
          retry
        else
          raise
        end
      end
    end

    desc "Download pre-cached entities from an S3 bucket"
    task :download do
      wait = ENV['WAIT'] ? ENV['WAIT'].to_i : 60*45
      bucket = _get_bucket

      if wait > 0
        puts "Waiting for #{CACHE_TARBALL} ..."
        STDOUT.flush
        bucket.wait_for(wait) {
          bucket.files.find { |f| f.key == CACHE_TARBALL }
        } or raise "Timed out waiting for #{CACHE_TARBALL}"
      end

      puts "Downloading #{CACHE_TARBALL} ..."
      File.open(CACHE_TARBALL, 'w') { |tarball_file|
        bucket.files.get(CACHE_TARBALL) { |tarball_contents, _, _|
          tarball_file.write(tarball_contents)
        }
      }

      sh "tar -xzf #{CACHE_TARBALL}"
    end

    desc "Download pre-cached entities from an S3 bucket if available; download normally and cache if not available."
    task :download_or_upload do
      bucket = _get_bucket
      if bucket.files.find { |f| f.key == CACHE_TARBALL }
        Rake::Task["s3cache:download"].invoke
      else
        Rake::Task["s3cache:upload"].invoke
      end
    end
  end
end
