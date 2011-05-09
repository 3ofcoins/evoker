Feature: overridable parameters

Check that smart_const function works as desired, based on PYTHON
parameter of evoker/python module.

Background:
      Given a clean working directory

Scenario Outline: parameters
                  Given Rakefile.parameters<rf> file as Rakefile
                   When I run: rake --trace print_python <env>
                   Then last command output contains: PYTHON=<python>
        Examples:
          | rf | env              | python    |
          |  1 |                  | python    |
          |  1 | PYTHON=python2.7 | python2.7 |
          |  2 |                  | python2.6 |
          |  2 | PYTHON=python2.7 | python2.7 |
          |  3 |                  | python2.6 |
          |  3 | PYTHON=python2.7 | python2.7 |
          |  4 |                  | python2.6 |
          |  4 | PYTHON=python2.7 | python2.7 |
