# Tasks to aid in the deployment of PEAR packages.

require 'capistrano'

Capistrano::Configuration.instance(:must_exist).load do

  set :pear_path,     shared_path unless exists?(:pear_path)
  set :pear_conf,     File.join(pear_path, 'pear.conf') unless exists?(:pear_conf)
  set :pear_channels, [] unless exists?(:pear_channels)
  set :pear_packages, [] unless exists?(:pear_packages)
  set :pear_exec,     File.join(pear_path, 'pear', 'pear')
  set :pear_cmd,      "#{pear_exec} -c #{pear_conf}"

  after  'deploy:setup',  'pear:setup'
  after  'deploy:setup',  'pear:discover_channels'
  before 'deploy', 'pear:update_channels'
  before 'deploy', 'pear:install_packages'

  namespace :pear do
    desc "Set up private PEAR repository."
    task :setup, :roles => :app do
      # Initially we must rely on the system-provided PEAR executable to bootstrap
      run "mkdir -p #{pear_path}"
      run "pear config-create #{pear_path} #{pear_conf}"
      run "pear -c #{pear_conf} install pear"
    end

    desc "Discover configured PEAR channels"
    task :discover_channels, :roles => :app do
      pear_channels.each do |channel|
        run "#{pear_cmd} channel-info #{channel} || #{pear_cmd} channel-discover #{channel}"
      end
    end

    desc "Update configured PEAR channels"
    task :update_channels, :roles => :app do
      pear_channels.each do |channel|
        run "#{pear_cmd} channel-update #{channel}"
      end
    end

    desc "Install PEAR packages"
    task :install_packages, :roles => :app do
      pear_packages.each do |package|
        run "#{pear_cmd} list #{package} || #{pear_cmd} install #{package}"
        if pear_package_scripts.keys.include? package
          inputs = pear_package_scripts[package]
          run "echo -n '#{inputs.join('\n')}' | #{pear_cmd} run-scripts #{package}"
        end
      end
    end
  end
end

