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
  
}



################################################################
################################# ------- Main----> function calls ----------#####################
#verify_vfs_are_created
#create_sriov_and_ovs_offload_enabled_instance