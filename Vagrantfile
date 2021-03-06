require "yaml"

# Load up our vagrant config files -- vagrantconfig.yaml first
_config = YAML.load(File.open(File.join(File.dirname(__FILE__),
                    "vagrantconfig.yaml"), File::RDONLY).read)

# Local-specific/not-git-managed config -- vagrantconfig_local.yaml
begin
    _config.merge!(YAML.load(File.open(File.join(File.dirname(__FILE__),
                   "vagrantconfig_local.yaml"), File::RDONLY).read))
rescue Errno::ENOENT # No vagrantconfig_local.yaml found -- that's OK; just
                     # use the defaults.
end

CONF = _config


Vagrant::Config.run do |config|
  config.vm.box = "CentOS 6.4 x86_64 Minimal"
  config.vm.box_url = "http://developer.nrel.gov/downloads/vagrant-boxes/CentOS-6.4-x86_64-v20131103.box"

  Vagrant.configure("1") do |config|
    config.vm.customize ["modifyvm", :id, "--memory", CONF['memory']]
  end

  Vagrant.configure("2") do |config|
    config.vm.provider "virtualbox" do |v|
      v.name = "Socorro_VM"
      v.customize ["modifyvm", :id, "--memory", CONF['memory']]
    end
  end

  is_jenkins = ENV['USER'] == 'jenkins'

  if not is_jenkins
    # Don't share these resources when on Jenkins. We want to be able to
    # parallelize jobs.

    config.vm.network :hostonly, "10.11.12.13"
  end

   # Enable symlinks, which google-breakpad uses during build:
  Vagrant.configure("1") do |config|
    config.vm.customize ["setextradata", :id,
                         "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root",
                         "1"]
  end

  Vagrant.configure("2") do |config|
    v.customize ["setextradata", :id,
                 "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root",
                 "1"]
  end

  if CONF['boot_mode'] == 'gui'
    config.vm.boot_mode = :gui
  end

  MOUNT_POINT = '/home/vagrant/src/socorro'

  # Don't mount shared folder over NFS on Jenkins; NFS doesn't work there yet.
  if is_jenkins or CONF['nfs'] == false or RUBY_PLATFORM =~ /mswin(32|64)/
    config.vm.share_folder("vagrant-root", MOUNT_POINT, ".",
                           :mount_options => ['dmode=777', 'fmode=777'])
  else
    config.vm.share_folder("vagrant-root", MOUNT_POINT, ".", :nfs => true)
  end

  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "puppet/manifests"
    puppet.manifest_file = "init.pp"
    # enable this to see verbose and debug puppet output
    if CONF['debug_mode'] == true
      puppet.options = "--verbose --debug"
    end
  end
end
