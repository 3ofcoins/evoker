Feature: Python virtualenv can be created

Background:
      Given a clean working directory
        And virtualenv example as Rakefile

Scenario: create virtual environment
     When I run: rake
     Then file python.stamp exists
      And directory python/ exists
      And file python/bin/python exists

     When I run: python/bin/python -c 'import sys ; print sys.path'
     Then last command output matches /python\/lib\/python[\d.]+\/site-packages/
