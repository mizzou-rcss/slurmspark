#!/bin/bash - 
#===============================================================================
#
#          FILE: pre_setup.sh
# 
#         USAGE: ./pre_setup.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Micheal Quinn (), quinnm@missouri.edu
#  ORGANIZATION: 
#       CREATED: 10/06/2015 03:57:31 PM CDT
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
#-------------------------------------------------------------------------------
# CONFIG
#-------------------------------------------------------------------------------
source ${SCRIPT_HOME}/config.sh
source ${SCRIPT_HOME}/helper_functions.sh

#-------------------------------------------------------------------------------
#  FUNCTIONS
#-------------------------------------------------------------------------------
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

spark::set_rank() {
  local node_list=( $(scontrol show hostnames "$1" | paste -s -d " " | sort) )
  local write_config="$2"
  local master_node="${node_list[0]}"
  local slave_nodes="${node_list[@]:1}"

  SPARK_MASTER_IP="$master_node"
  
  if [[ "$write_config" == "true" ]]; then
    echo "$master_node" > ${SPARK_CONF_DIR}/masters;

    for i in $slave_nodes; do
      echo "$i" >> ${SPARK_CONF_DIR}/slaves;
    done
  fi
}

spark::env_config() {
  if [[ ! -f ${SPARK_CONF_DIR}/spark-env.sh ]]; then
    touch ${SPARK_CONF_DIR}/spark-env.sh
    chmod +x ${SPARK_CONF_DIR}/spark-env.sh
  fi
  
  echo "SPARK_LOG_DIR=${SPARK_LOG_DIR}"                     >  ${SPARK_CONF_DIR}/spark-env.sh
  echo "SPARK_CONF_DIR=${SPARK_CONF_DIR}"                   >> ${SPARK_CONF_DIR}/spark-env.sh
  echo "SPARK_MASTER_IP=${SPARK_MASTER_IP}"                 >> ${SPARK_CONF_DIR}/spark-env.sh
  echo "SPARK_MASTER_PORT=${SPARK_MASTER_PORT}"             >> ${SPARK_CONF_DIR}/spark-env.sh
  echo "SPARK_MASTER_WEBUI_PORT=${SPARK_MASTER_WEBUI_PORT}" >> ${SPARK_CONF_DIR}/spark-env.sh
  echo "SPARK_WORKER_CORES=${SPARK_WORKER_CORES}"           >> ${SPARK_CONF_DIR}/spark-env.sh
  echo "SPARK_WORKER_MEMORY=${SPARK_WORKER_MEMORY}"         >> ${SPARK_CONF_DIR}/spark-env.sh
}

spark::env_export() {
  export SPARK_LOG_DIR=${SPARK_LOG_DIR}
  export SPARK_CONF_DIR=${SPARK_CONF_DIR}
  export SPARK_MASTER_IP=${SPARK_MASTER_IP}
  export SPARK_MASTER_PORT=${SPARK_MASTER_PORT}
  export SPARK_MASTER_WEBUI_PORT=${SPARK_MASTER_WEBUI_PORT}
  export SPARK_WORKER_CORES=${SPARK_WORKER_CORES}
  export SPARK_WORKER_MEMORY=${SPARK_WORKER_MEMORY}
}

main() {
  make::dirs
  
  if [[ "$SLURM_NODEID" == "0" ]]; then
    spark::set_rank "$SLURM_JOB_NODELIST" "true"
    spark::env_config
    spark::env_export
  else
    spark::set_rank "$SLURM_JOB_NODELIST" "false"
    spark::env_export
  fi

  env > ${SPARK_LOG_DIR}/$(hostname).pre.env
}

main
