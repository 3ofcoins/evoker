Feature: Basic Entity tasks work

Given a clean working directory
  And entity example as Rakefile

Scenario: run example rakefile on empty directory
 When I run: rake
 Then file foo.stamp exists
  And file foo/bar/baz exists
  And last command output contains: rm -rf foo
  And last command output contains: echo xyzzy > foo/bar/baz

Scenario: rerun rake and see that nothing happens
 When I run: rake
 Then file foo.stamp exists
  And file foo/bar/baz exists
  But last command output does not contain: rm -rf foo
  And last command output does not contain: echo xyzzy > foo/bar/baz

Scenario: rerun rake after removing stamp file
 When I run: rm foo.stamp
  And I run: rake
 Then file foo.stamp exists
  And file foo/bar/baz exists
  And last command output contains: rm -rf foo
  And last command output contains: echo xyzzy > foo/bar/baz

Scenario: rerun rake after removing target directory
 When I run: rm -rf foo
  And I run: rake
 Then file foo.stamp exists
  And file foo/bar/baz exists
  And last command output contains: rm -rf foo
  And last command output contains: echo xyzzy > foo/bar/baz

Scenario: run rake clobber
 When I run: rake clobber
 Then file foo.stamp does not exist
  And file foo/ does not exist
  And last command output contains: rm -r foo.stamp
  And last command output contains: rm -r foo
