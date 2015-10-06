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

#-------------------------------------------------------------------------------
# SCRIPT CONFIG  
#-------------------------------------------------------------------------------
SPARK_NODE_RANK="$SLURM_NODEID"
SPARK_VERSION="1.4.1-hadoop2.6"
SPARK_HOME="${HOME}/spark/spark-${SPARK_VERSION}"
SPARK_LOG_DIR="${SPARK_HOME}/logs/${SLURM_JOB_ID}"
SPARK_CONF_DIR="${SPARK_HOME}/conf/${SLURM_JOB_ID}"
SPARK_PID_DIR="${SPARK_HOME}/pid/${SLURM_JOB_ID}"
SPARK_MEM=$(scontrol show jobid $SLURM_JOB_ID | grep Memory | awk '{print $2}' | awk -F"=" '{print $2}')

SLURM_WALLTIME="$(squeue -j ${SLURM_JOB_ID} -h -o %L)"

JAVA_HOME="/usr/lib/jvm/java-1.7.0"
SSH_OPTS="-o StrictHostKeyChecking=no"

#-------------------------------------------------------------------------------
#  FUNCTIONS
#-------------------------------------------------------------------------------
slurm::walltime_to_min () {
    local walltime="$1"
    local numcolons="$(echo ${walltime} | awk -F: '{print NF-1}')"
    local fallback_walltime="$(sacctmgr -n list association account=general format="MaxWall" | head -n1 | sed 's/\-/\:/g')"
    local walltimetominutes=""

    case $numcolons in
      '0' ) if [[ "$walltime" == "UNLIMITED" ]]; then
              walltimetominutes=$(echo ${fallback_walltime} | awk -F':' '{print $1 * 24 * 60 + $2 + $3 / 60}' | xargs printf "%1.0f")
            fi
        ;;
      '1' ) walltimetominutes=$(echo ${walltime} | awk -F':' '{print $1 + $2 / 60}' | xargs printf "%1.0f");;
      '2' ) walltimetominutes=$(echo ${walltime} | awk -F':' '{print $1 * 60 + $2 + $3 / 60}' | xargs printf "%1.0f");;
    esac
    echo "$walltimetominutes"
}

slurm::wait() {
  local waittime="$1"
  local iterations="$(($waittime * 2))"
  
  for ((i = 1; i <= ${iterations}; i++)); do
    sleep 30
  done
}

make::dirs() {
  if [[ ! -d ${SPARK_LOG_DIR} ]]; then
    mkdir -p ${SPARK_LOG_DIR}
  fi
  if [[ ! -d ${SPARK_CONF_DIR} ]]; then
    mkdir -p ${SPARK_CONF_DIR}
  fi
  if [[ ! -d ${SPARK_PID_DIR} ]]; then
    mkdir -p ${SPARK_PID_DIR}
  fi
}

env::rank() {
  local nodeid="$1"

  case $nodeid in
    '0' ) echo "$(hostname) elected master";
          echo "$(hostname)" > ${SPARK_CONF_DIR}/masters;
          return 0;
          ;;
     *  ) echo "$(hostname) defined as worker";
          echo "$(hostname)" >> ${SPARK_CONF_DIR}/slaves;
          return 1;
          ;;
  esac
}

spark::env_config() {
  export SPARK_WORKER_MEMORY=${SPARK_MEM}
  export SPARK_LOG_DIR=${SPARK_LOG_DIR}
  export SPARK_CONF_DIR=${SPARK_CONF_DIR}
}

spark_master::start_master() {
  echo "Attempting to start Master on $(hostname)"
  /bin/bash "$SPARK_HOME/sbin/start-master.sh"
}
spark_master::start_slaves() {
  echo "Attempting to start Slaves"
  env
  /bin/bash "$SPARK_HOME/sbin/start-slaves.sh"
}

spark_master::wait_for_info() {
  local master_log="${SPARK_LOG_DIR}/*master.Master*.out"

  while true; do
    if grep -q "INFO Utils: Successfully started service 'sparkMaster' on port" $master_log; then
      break
    fi
    sleep 0.5
  done
  while true; do
    if grep -q "INFO Utils: Successfully started service on port" $master_log; then
      break
    fi
    sleep 0.5
  done
  while true; do
    if grep -q "INFO Utils: Successfully started service 'MasterUI' on port" $master_log; then
      break
    fi
    sleep 0.5
  done
  while true; do
    if grep -q "INFO MasterWebUI: Started MasterWebUI at" $master_log; then
      break
    fi
    sleep 0.5
  done
}

spark_master::get_print_info() {
  local master_log="${SPARK_LOG_DIR}/*master.Master*.out"
  local spark_master_ip="$(dig $(hostname) +short)"

  local spark_master_port=$(grep "INFO Utils: Successfully started service 'sparkMaster' on port" $master_log \
                            | awk -F 'port ' '{print $2}' | sed 's/\.$//g')
  local spark_service_port=$(grep "INFO Utils: Successfully started service on port" $master_log \
                             | awk -F 'port ' '{print $2}' | sed 's/\.$//g')
  local spark_ui_port=$(grep "INFO Utils: Successfully started service 'MasterUI' on port" $master_log \
                        | awk -F 'port ' '{print $2}' | sed 's/\.$//g')
  local spark_ui_url=$(grep "INFO MasterWebUI: Started MasterWebUI at" $master_log \
                       | grep -iIohE 'https?://[^[:space:]]+')
  
  echo "#-------------------------------------------------------------------------------"
  echo "# SPARK MASTER INFO"
  echo "#-------------------------------------------------------------------------------"
  echo "            IP : $spark_master_ip"
  echo "   Master Port : $spark_master_port"
  echo "  Service Port : $spark_service_port"
  echo "    WebUI Port : $spark_ui_port"
  echo "     WebUI URL : $spark_ui_url"
  echo "#-------------------------------------------------------------------------------"
}

main() {
  local wait_time="$(slurm::walltime_to_min "$SLURM_WALLTIME")"
  make::dirs
  spark::env_config
  
  env::rank "$SPARK_NODE_RANK"
  if [[ "$?" == "0" ]]; then
    spark_master::start_master
    spark_master::wait_for_info
    spark_master::get_print_info
    spark_master::start_slaves
    slurm::wait "$wait_time"
  fi
}

main
