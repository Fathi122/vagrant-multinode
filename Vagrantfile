# Vagrant configuration for ubuntu focal based multinode setup with static ips communcating with ssh
numbernodes=2
static_ip="192.168.56"
setup="init_setup"
sshcfg="ssh_setup"

# configure ansible hosts on master node
$ansiblehosts = <<SCRIPT
ANSIBLEHOSTSFILE=/etc/ansible/hosts
echo "Adding new entry in ${ANSIBLEHOSTSFILE}"
if [  -f "${ANSIBLEHOSTSFILE}" ];then
sudo tee -a "${ANSIBLEHOSTSFILE}" &>/dev/null <<'EOF'
[ansible_client]
node2
[all:vars]
ansible_connection=ssh
ansible_user=vagrant
ansible_ssh_pass=vagrant
EOF
fi
SCRIPT

# Vagrant configuration
Vagrant.configure("2") do |config|
  # Execute global script
  config.vm.provision "shell",privileged: false, path: "script/setup.sh",args: [numbernodes,"#{static_ip}","#{setup}"]
  prefix="node"
  #Apply config per node
  (1..numbernodes).each do |i|
    vm_name = "#{prefix}#{i}"
    config.vm.define vm_name do |node|
      node.vm.box = "ubuntu/focal64"
      node.vm.hostname = vm_name
      node.vm.network "private_network", ip: "#{static_ip}.#{10+i}"
    end
    # Run the SSH configuration script
    config.vm.provision "shell",privileged: false, path: "script/setup.sh",args: [numbernodes,"#{static_ip}","#{sshcfg}"]
    # Run update ansible hosts update
    config.vm.provision "ansiblehostscfg", type: "shell", privileged: false, inline: $ansiblehosts
  end
end
