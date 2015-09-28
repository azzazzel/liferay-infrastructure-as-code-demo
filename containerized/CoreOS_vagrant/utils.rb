
# Default values for the config options

PROVISIONING_DIR          = File.join(File.dirname(__FILE__), "provisioning")
PROVISIONING_MOINT_POINT  = "/provisioning";
USER_DATA_FILE_DEST       = "/var/lib/coreos-vagrant/vagrantfile-user-data"

$update_channel = "alpha"
$image_version = "current"

$m_num_instances = 1
$m_instance_name_prefix = "manager"
$m_vm_gui = false
$m_vm_memory = 512
$m_vm_cpus = 1
$m_ip_prefix = "192.168.100."
$m_netmask = "255.255.0.0"

$w_num_instances = 1
$w_instance_name_prefix = "worker"
$w_vm_gui = false
$w_vm_memory = 1024
$w_vm_cpus = 1
$w_ip_prefix = "192.168.200."
$w_netmask = "255.255.0.0"

$f_num_instances = 1
$f_instance_name_prefix = "frontend"
$f_vm_gui = false
$f_vm_memory = 512
$f_vm_cpus = 1
$f_ip_prefix = "192.168.300."
$f_netmask = "255.255.0.0"


def prepareMachine (machine, node)
  machine.vm.hostname = node[:name]

  ["vmware_fusion", "vmware_workstation"].each do |vmware|
    machine.vm.provider vmware do |v|
      v.vmx['memsize'] = node[:memory]
      v.vmx['numvcpus'] = node[:cpus]
    end
  end

  machine.vm.provider :virtualbox do |vb|
    vb.gui = node[:gui]
    vb.memory = node[:memory]
    vb.cpus = node[:cpus]
    vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
    vb.customize ["modifyvm", :id, "--nictype2", "virtio"]
  end

  machine.vm.network :private_network, ip: node[:ip], :netmask => node[:netmask] 
end


def provisionAs (role, machine, node, initial_cluster)
    machine.vm.synced_folder ".", "/vagrant", disabled: true
    machine.vm.synced_folder "#{PROVISIONING_DIR}/#{role}", PROVISIONING_MOINT_POINT
    machine.vm.synced_folder "binary_repo", "/install"

    commands = []
    commands << "cp #{PROVISIONING_MOINT_POINT}/cloud-config.yml #{USER_DATA_FILE_DEST}"
    commands << "sed -i 's|__ETCD__SERVER_NAME__|#{node[:name]}|g' #{USER_DATA_FILE_DEST}"
    commands << "sed -i 's|__ETCD__INITIAL_CLUSTER__|#{initial_cluster}|g' #{USER_DATA_FILE_DEST}"
    commands << "sed -i 's|__ETCD__PUBLIC_IP__|#{node[:ip]}|g' #{USER_DATA_FILE_DEST}"
    # it seams since machine is already runnig, cloud init does not pick this before next restart
    # thus calling it explicitelly after provisioning 
    commands << "coreos-cloudinit --from-file #{USER_DATA_FILE_DEST}"

    commands.each do |command|
      machine.vm.provision :shell, :inline => command, :privileged => true
    end  

end

def getManagers ()
  managers = []
  initial_cluster = ""
  (1..$m_num_instances).each do |i|
    ip = "#{$m_ip_prefix}#{i+100}"
    name =  "%s-%02d" % [$m_instance_name_prefix, i]
    m = {
      :ip       => ip,
      :netmask  => $m_netmask,
      :name     => name,
      :memory   => $m_vm_memory,
      :cpus     => $m_vm_cpus,
      :gui      => $m_vm_gui
    }
    managers << m;

    node_string = "#{name}=http://#{ip}:2380"
    initial_cluster << (initial_cluster == "" ? node_string : ",#{node_string}")
  end

  return [managers, initial_cluster]  
end  


def getWorkers ()
  workers = []
  (1..$w_num_instances).each do |i|
    ip = "#{$w_ip_prefix}#{i+100}"
    name =  "%s-%02d" % [$w_instance_name_prefix, i]
    w = {
      :ip       => ip,
      :netmask  => $w_netmask,
      :name     => name,
      :memory   => $w_vm_memory,
      :cpus     => $w_vm_cpus,
      :gui      => $w_vm_gui
    }
    workers << w;
  end
  return workers  
end


def getFrontends ()
  frontends = []
  (1..$f_num_instances).each do |i|
    ip = "#{$f_ip_prefix}#{i+100}"
    name =  "%s-%02d" % [$f_instance_name_prefix, i]
    f = {
      :ip       => ip,
      :netmask  => $f_netmask,
      :name     => name,
      :memory   => $f_vm_memory,
      :cpus     => $f_vm_cpus,
      :gui      => $f_vm_gui
    }
    frontends << f;
  end
  return frontends  
end


def configureCoreOS (config, update_channel, image_version)
  config.vm.box = "coreos-%s" % update_channel
  if image_version != "current"
      config.vm.box_version = image_version
  end
  config.vm.box_url = "http://%s.release.core-os.net/amd64-usr/%s/coreos_production_vagrant.json" % [update_channel, image_version]

  ["vmware_fusion", "vmware_workstation"].each do |vmware|
    config.vm.provider vmware do |v, override|
      override.vm.box_url = "http://%s.release.core-os.net/amd64-usr/%s/coreos_production_vagrant_vmware_fusion.json" % [update_channel, image_version]
    end
  end
end


def fixPluginsAndAdditions (config)
  # On VirtualBox, we don't have guest additions or a functional vboxsf
  # in CoreOS, so tell Vagrant that so it can be smarter.
  config.vm.provider :virtualbox do |v|
    v.check_guest_additions = false
    v.functional_vboxsf     = false
  end

  # plugin conflict
  if Vagrant.has_plugin?("vagrant-vbguest") then
    config.vbguest.auto_update = false
  end
end