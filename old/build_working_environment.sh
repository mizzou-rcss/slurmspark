#!/bin/bash - 
#===============================================================================
#
#          FILE: build_working_environment.sh
# 
#         USAGE: ./build_working_environment.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Micheal Quinn (), quinnm@missouri.edu
#  ORGANIZATION: 
#       CREATED: 10/06/2015 08:40:29 AM CDT
#      REVISION:  ---
#===============================================================================
#-------------------------------------------------------------------------------
# BASH CONFIG
#-------------------------------------------------------------------------------
set -o nounset
source ${HOME}/slurmspark/config.sh

##-------------------------------------------------------------------------------
## SCRIPT CONFIG  
##-------------------------------------------------------------------------------
#JAVA_HOME="/usr/lib/jvm/java-1.7.0"
#SSH_OPTS="-o StrictHostKeyChecking=no"
#
#SLURM_WALLTIME="$(squeue -j ${SLURM_JOB_ID} -h -o %L)"
#
#SPARK_NODE_RANK="$SLURM_NODEID"
#SPARK_VERSION="1.4.1-hadoop2.6"
#SPARK_HOME="${HOME}/spark/spark-${SPARK_VERSION}"
#SPARK_LOG_DIR="${SPARK_HOME}/logs/${SLURM_JOB_ID}"
#SPARK_CONF_DIR="${SPARK_HOME}/conf/${SLURM_JOB_ID}"
#SPARK_PID_DIR="${SPARK_HOME}/pid/${SLURM_JOB_ID}"
#SPARK_MEM=$(scontrol show jobid $SLURM_JOB_ID | grep Memory | awk '{print $2}' | awk -F"=" '{print $2}')


#-------------------------------------------------------------------------------
#  FUNCTIONS
#-------------------------------------------------------------------------------
#slurm::walltime_to_min () {
#    local walltime="$1"
#    local numcolons="$(echo ${walltime} | awk -F: '{print NF-1}')"
#    local fallback_walltime="$(sacctmgr -n list association account=general format="MaxWall" | head -n1 | sed 's/\-/\:/g')"
#    local walltimetominutes=""
#
#    case $numcolons in
#      '0' ) if [[ "$walltime" == "UNLIMITED" ]]; then
#              walltimetominutes=$(echo ${fallback_walltime} | awk -F':' '{print $1 * 24 * 60 + $2 + $3 / 60}' | xargs printf "%1.0f")
#            fi
#        ;;
#      '1' ) walltimetominutes=$(echo ${walltime} | awk -F':' '{print $1 + $2 / 60}' | xargs printf "%1.0f");;
#      '2' ) walltimetominutes=$(echo ${walltime} | awk -F':' '{print $1 * 60 + $2 + $3 / 60}' | xargs printf "%1.0f");;
#    esac
#    echo "$walltimetominutes"
#}
#
#slurm::wait() {
#  local waittime="$1"
#  local iterations="$(($waittime * 2))"
#  
#  for ((i = 1; i <= ${iterations}; i++)); do
#    sleep 30
#  done
#}
#
#make::dirs() {
#  if [[ ! -d ${SPARK_LOG_DIR} ]]; then
#    mkdir -p ${SPARK_LOG_DIR}
#  fi
#  if [[ ! -d ${SPARK_CONF_DIR} ]]; then
#    mkdir -p ${SPARK_CONF_DIR}
#  fi
#  if [[ ! -d ${SPARK_PID_DIR} ]]; then
#    mkdir -p ${SPARK_PID_DIR}
#  fi
#}

#env::rank() {
#  local node_list=( $(scontrol show hostnames "$1" | paste -s -d " " | sort) )
#  local master_node="${node_list[0]}"
#  local slave_nodes="${node_list[@]:1}"
#    
#  echo "$master_node elected master";
#  echo "$master_node" > ${SPARK_CONF_DIR}/masters;
#  
#  for i in $slave_nodes; do
#    echo "$i is a worker";
#    echo "$i" >> ${SPARK_CONF_DIR}/slaves;
#  done
#}

#spark::env_config() {
#  export SPARK_WORKER_MEMORY=${SPARK_MEM}
#  export SPARK_LOG_DIR=${SPARK_LOG_DIR}
#  export SPARK_CONF_DIR=${SPARK_CONF_DIR}
#  
#  touch ${SPARK_CONF_DIR}/spark-env.sh
#  chmod +x ${SPARK_CONF_DIR}/spark-env.sh
#
#  echo "SPARK_WORKER_MEMORY=${SPARK_MEM}" >  ${SPARK_CONF_DIR}/spark-env.sh
#  echo "SPARK_LOG_DIR=${SPARK_LOG_DIR}"   >> ${SPARK_CONF_DIR}/spark-env.sh
#  echo "SPARK_CONF_DIR=${SPARK_CONF_DIR}" >> ${SPARK_CONF_DIR}/spark-env.sh
#}

spark_master::start_master() {
  echo "Attempting to start Master on $(hostname)"
  /bin/bash "$SPARK_HOME/sbin/start-master.sh"
}
spark_master::start_slaves() {
  echo "Attempting to start Slaves"
  /bin/bash "$SPARK_HOME/sbin/start-slaves.sh"
}

spark::get_set_info() {
  local master_log="${SPARK_LOG_DIR}/*master.Master*.out"
 
  local spark_master_ip="$(cat ${SPARK_CONF_DIR}/masters | head -n 1)"

  local spark_master_port=$(grep "INFO Utils: Successfully started service 'sparkMaster' on port" $master_log \
                            | awk -F 'port ' '{print $2}' | sed 's/\.$//g')
  local spark_service_port=$(grep "INFO Utils: Successfully started service on port" $master_log \
                             | awk -F 'port ' '{print $2}' | sed 's/\.$//g')
  local spark_ui_port=$(grep "INFO Utils: Successfully started service 'MasterUI' on port" $master_log \
                        | awk -F 'port ' '{print $2}' | sed 's/\.$//g')
  local spark_ui_url=$(grep "INFO MasterWebUI: Started MasterWebUI at" $master_log \
                       | grep -iIohE 'https?://[^[:space:]]+')
  
  export SPARK_MASTER_IP=${spark_master_ip}
  export SPARK_MASTER_PORT=${spark_master_port}
  export SPARK_SERVICE_PORT=${spark_service_port}
  export SPARK_UI_PORT=${spark_ui_port}
  export SPARK_UI_URL=${spark_ui_url}

  echo "SPARK_MASTER_IP=${spark_master_ip}"     >> ${SPARK_CONF_DIR}/spark-env.sh
  echo "SPARK_MASTER_PORT=${spark_master_port}" >> ${SPARK_CONF_DIR}/spark-env.sh
}

spark::wait_for_master() {
  local master_log="${SPARK_LOG_DIR}/*master.Master*.out"

  while true; do
    if grep -q "INFO Utils: Successfully started service 'sparkMaster' on port" $master_log 2>/dev/null; then
      echo "$(hostname) : Found sparkMaster port"
      break
    fi
    sleep 0.5
  done
  while true; do
    if grep -q "INFO Utils: Successfully started service on port" $master_log 2>/dev/null; then
      echo "$(hostname) : Found spark service port"
      break
    fi
    sleep 0.5
  done
  while true; do
    if grep -q "INFO Utils: Successfully started service 'MasterUI' on port" $master_log 2>/dev/null; then
      echo "$(hostname) : Found MasterUI port"
      break
    fi
    sleep 0.5
  done
  while true; do
    if grep -q "INFO MasterWebUI: Started MasterWebUI at" $master_log 2>/dev/null; then
      echo "$(hostname) : Found MasterWebUI"
      break
    fi
    sleep 0.5
  done
  echo "$(hostname) : Ready to accept connections"
}

spark::print_master_info() {
  echo "#-------------------------------------------------------------------------------"
  echo "# SPARK MASTER INFO"
  echo "#-------------------------------------------------------------------------------"
  echo "            IP : $SPARK_MASTER_IP"
  echo "   Master Port : $SPARK_MASTER_PORT"
  echo "  Service Port : $SPARK_SERVICE_PORT"
  echo "    WebUI Port : $SPARK_UI_PORT"
  echo "     WebUI URL : $SPARK_UI_URL"
  echo "#-------------------------------------------------------------------------------"
}

spark_slave::start_slave() {
  local spark_master_ip="$1"
  local spark_master_port="$2"
  local master_uri="spark://${spark_master_ip}:${spark_master_port}"
 
  echo "Attempting to start Slave on $(hostname)"
  /usr/bin/bash "$SPARK_HOME/sbin/start-slave.sh ${master_uri}"
}


main() {
  local wait_time="$(slurm::walltime_to_min "$SLURM_WALLTIME")"
  make::dirs
  
  if [[ "$SPARK_NODE_RANK" == "0" ]]; then
    env::rank "$SLURM_JOB_NODELIST"
    spark::env_config
    spark_master::start_master
    spark::wait_for_master
    spark::get_set_info
    spark::print_master_info
#    spark_master::start_slaves
  #else
    #spark::wait_for_master
    #spark::get_set_info
    #spark_slave::start_slave "$SPARK_MASTER_IP" "$SPARK_MASTER_PORT"
  fi
  
  slurm::wait "$wait_time"
}

main
