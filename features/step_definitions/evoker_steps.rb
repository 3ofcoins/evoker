require 'fileutils'

DIR="_tests"

Given /^a clean working directory$/ do
  FileUtils.rm_rf DIR
  Dir.mkdir DIR
end

Given /^(\S+) example as Rakefile$/ do |example|
  FileUtils.cp "examples/Rakefile.#{example}", "#{DIR}/Rakefile"
end

When /^I run: (.*)$/ do |command|
  system "cd #{DIR} ; #{command} > .log 2>&1"
end

When /^I remove (.*)$/ do |f|
  FileUtils.rm_rf "#{DIR}/"+f
end

Then /^file (\S+) exists$/ do |f|
  (File.exists? "#{DIR}/"+f).should == true
end

Then /^directory (\S+) exists$/ do |f|
  (File.directory? "#{DIR}/"+f).should == true
end

Then /^file (\S+) does not exist$/ do |f|
  (File.exists? "#{DIR}/"+f).should == false
end

Then /^last command output contains: (.*)$/ do |output|
  File.read("#{DIR}/.log").should include(output)
end

Then /^last command output does not contain: (.*)$/ do |output|
  File.read("#{DIR}/.log").should_not include(output)
end

