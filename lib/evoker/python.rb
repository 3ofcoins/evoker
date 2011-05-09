# Python stuff

require 'evoker'

module Evoker
  smart_const(:python, 'python')
  smart_const(:pip, 'pip')
  smart_const(:virtualenv_version, '1.6.1')

  # Create Python virtual environment
  def virtualenv(*args)
    if args.last.is_a? Hash
      opts = args.pop
    else
      opts = {}
    end
    
    if opts[:download_virtualenv]
      opts[:python] ||= smart_const_get(:python)
      opts[:virtualenv] = "#{opts[:python]} ./virtualenv.py"
      opts[:virtualenv_version] ||= smart_const_get(:virtualenv_version)
      opts[:virtualenv_url] ||= "http://github.com/pypa/virtualenv/raw/#{opts[:virtualenv_version]}/virtualenv.py"
      wget_virtualenv = wget opts[:virtualenv_url],
        :args => '--no-check-certificate',
        :no_entity => true
      CLOBBER.add(['virtualenv.pyc', 'setuptools-*.egg'])
    else
      opts[:virtualenv] ||= 'virtualenv'
      wget_virtualenv = nil
    end
    opts[:args] ||= nil

    virtualenv_command = "#{opts[:virtualenv]}"
    virtualenv_command << " #{opts[:args]}" if opts[:args]

    desc "Python virtual environment"
    venv = entity(*args) do |t|
      sh "#{virtualenv_command} #{t.name}"
    end

    task venv => wget_virtualenv if wget_virtualenv
    venv
  end
  module_function :virtualenv

  # Create a symbolic link to virtualenv's site-packages dir
  def virtualenv_site_package(path, opts={})
    opts[:target] ||= File.basename(path)
    opts[:virtualenv] ||= :python
    venv = Rake::Task[opts[:virtualenv]].name
    ln_sf File.join('..', '..', '..', '..', path),
          File.join(Dir["#{venv}/lib/python*/site-packages"].first,
                    opts[:target])
  end
  module_function :virtualenv_site_package

  # Download Python requirements using pip
  def pip_requirements(file, args={})
    stampfile = "#{file}.stamp"
    if args[:virtualenv]
      args[:pip] = "#{args[:virtualenv]}/bin/pip"
    else
      args[:pip] ||= smart_const_get(:pip)
    end
    pip_cmd = "#{args[:pip]}"
    pip_cmd << " #{args[:args]}" if args[:args]
    pip_cmd << " install"
    pip_cmd << " #{args[:install_args]}" if args[:install_args]
    pip_cmd << " -r #{file}"

    t = file stampfile => file do
      sh pip_cmd
      File.open(stampfile, 'w') { |f| f.write(DateTime::now.to_s) }
    end
    task t => args[:virtualenv] if args[:virtualenv]
    CLOBBER.add t.name
    ENTITIES.add t.name
    t
  end
  module_function :pip_requirements
end
