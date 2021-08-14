#!/bin/bash

numnodes=$1
static_ip=$2

update_etchost()
{
    echo "setting /etc/hosts for $HOSTNAME to resolve node$2"
    echo "${static_ip}.$1 node$2" | sudo tee -a /etc/hosts &>/dev/null
}

node_configuration ()
{
    # SSH with password authentication.
    sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
 
    # Update cache
    sudo apt-get update -y
    # Install sshpass and net-tools
    sudo apt-get install sshpass net-tools -y
    
    if [[ "$HOSTNAME" == "node1" ]]; then
      echo ">>>> Install ansible on node1"
      sudo apt-get install ansible -y
    fi
    
    # Exclude node* from host checking
    cat > /home/vagrant/.ssh/config <<'EOF'
    Host node*
       StrictHostKeyChecking no
       UserKnownHostsFile=/dev/null
EOF
    echo ">>>> dumping ssh config"
    cat /home/vagrant/.ssh/config
    # Populate /etc/hosts with the IP and node names
    nodeend=$((10+$numnodes))
    for (( x=11; x<=$nodeend; x++ )); do
       nodeidx=$(($x-10))
       if [[ "$HOSTNAME" == "node$nodeidx" ]]; then
          echo "Skipping node$nodeidx"
          continue
       fi
       grep "${static_ip}.${x}" /etc/hosts &>/dev/null || update_etchost "$x" "$nodeidx"
    done
    yes y |ssh-keygen -f /home/vagrant/.ssh/id_rsa -t rsa -N ''
    echo " >>>> SSH Key Pair created for ${HOSTNAME}" 
}

ssh_configuration()
{
    for (( x=1; x<$numnodes+1; x++ ))
    do
       # Skip the current host.
       if [[ "$HOSTNAME" == "node$x" ]]; then
          echo ">>>> Skipping node$x"
          continue
       fi
 
       # Copy the current host public key to remote host.
       if [[ "$HOSTNAME" != "node1" ]]; then
         echo ">>>> Copying public key to node$x"
         sshpass -p vagrant ssh-copy-id -i /home/vagrant/.ssh/id_rsa.pub "node$x"
         echo "    Copied public key to node$x <<<<"
       fi
    done

    # Set the permissions to config
    sudo chmod 0600 /home/vagrant/.ssh/config
    # restart the SSHD daemon
    sudo systemctl restart sshd
    echo ">>>> SSH Key based Auth configuration completed" 
}

runningmod="$3"
echo "running mode : ${runningmod}"
if [[ "${runningmod}" == "init_setup" ]];then
   node_configuration
elif [[ "${runningmod}" == "ssh_setup" ]];then
   ssh_configuration
else
   echo ">>>> Wrong Mode selected"
fi