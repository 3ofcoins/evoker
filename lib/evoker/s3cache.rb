# Caching of downloaded upstream stuff as a tarball in an S3 bucket.

require 'evoker'
require 'fog'

module Evoker
  def _get_bucket
    $s3 ||= Fog::Storage.new(
      :provider => "AWS",
      :aws_access_key_id => CACHE_S3_ACCESS_KEY_ID,
      :aws_secret_access_key => CACHE_S3_SECRET_ACCESS_KEY)
    $bucket ||= $s3.directories.get(CACHE_S3_BUCKET)
  end

  desc "Store all downloaded entities in an S3 bucket"
  task :cache => ENTITIES do
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
    sh "tar -czf #{CACHE_TARBALL} --exclude '#{CACHE_BASENAME}*.tgz' ."
    puts "INFO: uploading #{CACHE_TARBALL} to #{CACHE_S3_BUCKET}..."
    File.open(CACHE_TARBALL, 'r') do |tarball|
      bucket.files.create(
        :key => CACHE_TARBALL,
        :body => tarball)
    end
  end

  desc "Download pre-cached entities from an S3 bucket"
  task :uncache do
    wait = ENV['WAIT'] ? ENV['WAIT'].to_i : 60*45
    bucket = _get_bucket

    if wait > 0
      print "Waiting for #{CACHE_TARBALL} .."
      STDOUT.flush
      bucket.wait_for(wait) {
        print '.'
        STDOUT.flush
        bucket.files.find { |f| f.key == CACHE_TARBALL }
      } or raise "Timed out waiting for #{CACHE_TARBALL}"
      puts " got it."
    end

    print "Downloading #{CACHE_TARBALL} .."
    STDOUT.flush
    File.open(CACHE_TARBALL, 'w') { |tarball_file|
      bucket.files.get(CACHE_TARBALL) { |tarball_contents, _, _|
        print '.'
        STDOUT.flush
        tarball_file.write(tarball_contents)
      }
    }
    puts " got it."

    sh "tar -xvf #{CACHE_TARBALL}"
  end

  desc "Download pre-cached entities from an S3 bucket if available; download normally and cache if not available."
  task :uncache_or_cache do
    bucket = _get_bucket
    if bucket.files.find { |f| f.key == CACHE_TARBALL }
      Rake::Task[:uncache].execute
    else
      Rake::Task[:cache].execute
    end
  end
end
