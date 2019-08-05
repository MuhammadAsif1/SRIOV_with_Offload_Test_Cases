#!/bin/bash

################## ------- Varibales ----------###################
###-- 3 compute nodes ---##
compute_node1_ip='192.168.10.140'
compute_node2_ip='192.168.10.140'
compute_node3_ip='192.168.10.140'
###-- 3 controller nodes ---##
controller_node1_ip='192.168.10.140'
controller_node2_ip='192.168.10.140'
controller_node3_ip='192.168.10.140'

output1=''
output2=''
output3=''
pf_id='' #pd id from compute nodes
vfs_output='' #output of 'ip link show $pf_id'

flavor='m1.sriov_ovs_offload'

physical_network='physint'
network='sriov_net'
subnet='sriov_sub'
port='sriov_p1'
port2='sriov_p2'
availability_zone1='nova0'
availability_zone2='nova1'
image='centos'
instance='sriov_vm1'
instance2='sriov_vm2'
vm_on_node='compute_node1_ip'
public_network='public'
router='sriov_router1'
Floating_IP=''
Floating_IP2=''
################################################################
validate_the_switch_mode_for_ovs-offloading()
{
  cd /pilot/templates
   
}
################################################################
verify_vfs_are_created()
{
  output1=$(ssh osm@$compute_node1_ip 'ip link show $pf_id') # 
  
  output2=$(ssh osm@$compute_node2_ip 'ip link show $pf_id')
  
  output3=$(ssh osm@$compute_node3_ip 'ip link show $pf_id')
  
  if [ $output1 = $vfs_output ] && [ $output2 = $vfs_output ] && [ $output3 = $vfs_output ]
  then
    echo $output
    echo '========================================================================================='
    echo '========== Test Case executed Successfully, Cinder is enabled to use Barbican ==========='
    echo '========================================================================================='
  else
    echo '========================================================================================='
    echo '=============== Test Case Failed, Cinder is not enabled to use Barbican ================='
    echo '========================================================================================='
  fi   
}
################################################################
create_sriov_and_ovs_offload_enabled_instance()
{
  echo "========= Creating flavor ========"
  echo "========= Creating flavor ========" > create_sriov_and_ovs_offload_enabled_instance.log
  output1=$(openstack flavor create $flavor --ram 4096 --disk 30 --vcpu 4)
  echo "$output1"
  echo "$output1" >> create_sriov_and_ovs_offload_enabled_instance.log
  echo "========= Setting flavor Properites ========"
  echo "========= Setting flavor Properites ========" >> create_sriov_and_ovs_offload_enabled_instance.log
  output1=$(openstack flavor set --property sriov=true --property hw:mem_page_size=1GB $flavor)
  echo "$output1"
  echo "$output1" >> create_sriov_and_ovs_offload_enabled_instance.log
  echo "========= Creating SRIOV Enabled Network ========"
  echo "========= Creating SRIOV Enabled Network ========" >> create_sriov_and_ovs_offload_enabled_instance.log
  output1=$(openstack network create --provider-network-type=vlan --provider-physical-network=$physical_network $network)
  echo "$output1"
  echo "$output1" >> create_sriov_and_ovs_offload_enabled_instance.log
  echo "========= Creating SRIOV Subent ========"
  echo "========= Creating SRIOV Subent ========" >> create_sriov_and_ovs_offload_enabled_instance.log
  output1=$(openstack subnet create $subnet --network $network --subnet-range 192.168.50.0/24)
  echo "$output1"
  echo "$output1" >> create_sriov_and_ovs_offload_enabled_instance.log
  echo "========= Creating Router ========"
  echo "========= Creating Router ========" >> create_sriov_and_ovs_offload_enabled_instance.log
  output1=$(openstack router create $router)
  echo "$output1" >> create_sriov_and_ovs_offload_enabled_instance.log
  echo "$output1"
  ####adding subnet in router
  output1=$(openstack router add subnet $router $subnet)
  echo "$output1" >> create_sriov_and_ovs_offload_enabled_instance.log
  echo "$output1"
  ####adding external gateway in router
  output1=$(openstack router set $router --external-gateway $public_network)
  echo "$output1"
  echo "$output1" >> create_sriov_and_ovs_offload_enabled_instance.log
  #### Creating Port 1 for instance 1
  echo "========= Creating Port 1 ========"
  echo "========= Creating Port 1 ========" >> create_sriov_and_ovs_offload_enabled_instance.log
  output1=$(openstack port create --network $network --vnic-type=direct --binding-profile '{"capabilities": ["switchdev"]}' $port)
  echo "$output1"
  echo "$output1" >> create_sriov_and_ovs_offload_enabled_instance.log
  #### Creating Port 2 for instance 2
  echo "========= Creating Port 2 ========"
  echo "========= Creating Port 2 ========" >> create_sriov_and_ovs_offload_enabled_instance.log
  output1=$(openstack port create --network $network --vnic-type=direct --binding-profile '{"capabilities": ["switchdev"]}' $port2)
  echo "$output1"
  echo "$output1" >> create_sriov_and_ovs_offload_enabled_instance.log
  ###creating instance 1 on availability_zone1=nova0
  echo "========= Creating Instance 1 ========"
  echo "========= Creating Instance 1 ========" >> create_sriov_and_ovs_offload_enabled_instance.log
  output1=$(openstack server create --flavor $flavor --availability-zone $availability_zone1 --image $image --nic port-id=$port $instance)
  echo "$output1"
  echo "$output1" >> create_sriov_and_ovs_offload_enabled_instance.log
  sleep 2m
  echo "========= Creating Instance 2 ========"
  echo "========= Creating Instance 2 ========" >> create_sriov_and_ovs_offload_enabled_instance.log
  output1=$(openstack server create --flavor $flavor --availability-zone $availability_zone2 --image $image --nic port-id=$port2 $instance2)
  echo "$output1"
  echo "$output1" >> create_sriov_and_ovs_offload_enabled_instance.log
  sleep 2m
  ##################### conditons for instance1 #############
  output=$(openstack server show $instance | awk '/status/ {print $4}')
  if [ $output = 'ACTIVE' ]
  then
    echo '========================================================================================='
    echo '===================== Instance 1 created  Created successfully ============================'
    echo '========================================================================================='
    echo '===================== Instance 1 created  Created successfully ============================' >> create_sriov_and_ovs_offload_enabled_instance.log
    for i in {1};do openstack port list --server "$instance" | awk -F "|" '/-/ {print $2}' | xargs -I{} openstack floating ip create --port {} public; echo "$instance"; done
    
    echo "creating floating ip ........... " >> create_sriov_and_ovs_offload_enabled_instance.log
    Floating_IP=$(openstack server list | awk "/$instance/"'{print $9}')
    echo "$Floating_IP" >> create_sriov_and_ovs_offload_enabled_instance.log
    sleep 10
    output=$(ping -c 1 $Floating_IP &> /dev/null && echo success || echo fail)
    if [ $output = 'success' ]
    then
      echo '=========================== instance 1 is reachable from external network ==========='
      echo '=========================== instance 1 is reachable from external network ===========' >> create_sriov_and_ovs_offload_enabled_instance.log
      ping -w $Floating_IP
    else 
      echo '=========================== ping unsuccessfull, test case failde ==========='
      echo '=========================== ping unsuccessfull, test case failde ===========' >> create_sriov_and_ovs_offload_enabled_instance.log
      ping -w $Floating_IP
    fi
  else
    echo '========================================================================================='
    echo '========================== Failed, Instance 1 not created ======================='
    echo '========================================================================================='
    echo '========================== Failed, Instance 1 not created =======================' >> create_sriov_and_ovs_offload_enabled_instance.log
  fi
  ######################################### conditions for instance 2 #######################
  output=$(openstack server show $instance2 | awk '/status/ {print $4}')
  if [ $output = 'ACTIVE' ]
  then
    echo '========================================================================================='
    echo '===================== Instance 2 created  Created successfully ============================'
    echo '========================================================================================='
    echo '===================== Instance 2 created  Created successfully ============================' >> create_sriov_and_ovs_offload_enabled_instance.log
    for i in {1};do openstack port list --server "$instance2" | awk -F "|" '/-/ {print $2}' | xargs -I{} openstack floating ip create --port {} public; echo "$instance2"; done
    
    echo "creating floating ip ........... " >> create_sriov_and_ovs_offload_enabled_instance.log
    Floating_IP2=$(openstack server list | awk "/$instance2/"'{print $9}')
    echo "$Floating_IP2" >> create_sriov_and_ovs_offload_enabled_instance.log
    sleep 10
    output=$(ping -c 1 $Floating_IP2 &> /dev/null && echo success || echo fail)
    if [ $output = 'success' ]
    then
      echo '=========================== instance 2 is reachable from external network ==========='
      echo '=========================== instance 2 is reachable from external network ===========' >> create_sriov_and_ovs_offload_enabled_instance.log
      ping -w $Floating_IP2
    else 
      echo '=========================== ping unsuccessfull, test case failde ==========='
      echo '=========================== ping unsuccessfull, test case failde ===========' >> create_sriov_and_ovs_offload_enabled_instance.log
      ping -w $Floating_IP2
    fi
  else
    echo '========================================================================================='
    echo '========================== Failed, Instance 2 not created ======================='
    echo '========================================================================================='
    echo '========================== Failed, Instance 2 not created =======================' >> create_sriov_and_ovs_offload_enabled_instance.log
  fi
}
###############################################################
verify_creation_of_representor_port()
{
  echo "================ Representor Port ================"
  echo "================ Representor Port ================" >> create_sriov_and_ovs_offload_enabled_instance.log
  output1=$(ssh heat-admin@$compute_node1_ip 'sudo ovs-dpctl show')
  echo "$output1"
  echo "$output1" >> create_sriov_and_ovs_offload_enabled_instance.log
}


################################################################
################################# ------- Main----> function calls ----------#####################
#verify_vfs_are_created
#create_sriov_and_ovs_offload_enabled_instance ### this function will create two instances on same or different compute node(depends on availability_zone1,availability_zone2 value), on same network..

