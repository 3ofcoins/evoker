# -*- mode: ruby; encoding: utf-8 -*-

lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'evoker/version'

Gem::Specification.new do |s|
  s.name = "evoker"
  s.version = Evoker::VERSION::STRING
  s.summary = "Rake add-on to download and manage project's external dependencies"
  s.description = <<EOF
Evoker is an add-on to Rake to download and manage project's external
dependencied, update them as needed, cache them, etc.
EOF

  s.authors = ["Maciej Pasternacki"]
  s.email = "maciej@pasternacki.net"
  s.homepage = "http://github.com/mpasternacki/evoker"
  s.licenses = ['BSD']

  s.add_dependency "rake"

  s.required_rubygems_version = ">= 1.3.6"
  s.files = Dir.glob("lib/**/*.rb") + %w(LICENSE)
  s.require_paths = ["lib"]
end
