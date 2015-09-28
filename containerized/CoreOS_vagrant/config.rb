# -------------------------
# Official CoreOS channel from which updates should be downloaded
# -------------------------
$update_channel='alpha'

# -------------------------
# Number of 'manager' instances
# These will 
#  - form the etc cluster
#  - be the once to install Kubernetes master on
# -------------------------
$m_num_instances = 1

# Parameters of 'manager' instances
$m_vm_cpus = 1
$m_vm_memory = 512
$m_vm_gui = false
$m_ip_prefix = "192.168.10."
$m_netmask = "255.255.0.0"

# -------------------------
# Number of 'worker' instances
# Thiese are where containers run
# -------------------------
$w_num_instances = 2

# Parameters of 'worker' instances
$w_vm_cpus = 2
$w_vm_memory = 2048
$w_vm_gui = false
$w_ip_prefix = "192.168.20."
$w_netmask = "255.255.0.0"

# -------------------------
# Number of 'frontend' instances
# Thiese are exposed to externall access and delegate requests to workers
# -------------------------
$f_num_instances = 1

# Parameters of 'worker' instances
$f_vm_cpus = 1
$f_vm_memory = 1024
$f_vm_gui = false
$f_ip_prefix = "192.168.30."
$f_netmask = "255.255.0.0"


