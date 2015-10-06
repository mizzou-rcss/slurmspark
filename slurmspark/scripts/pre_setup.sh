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

env::rank() {
  local node_list=( $(scontrol show hostnames "$1" | paste -s -d " " | sort) )
  local master_node="${node_list[0]}"
  local slave_nodes="${node_list[@]:1}"

  echo "$master_node elected master";
  echo "$master_node" > ${SPARK_CONF_DIR}/masters;

  for i in $slave_nodes; do
    echo "$i is a worker";
    echo "$i" >> ${SPARK_CONF_DIR}/slaves;
  done
}

spark::env_config() {
  export SPARK_WORKER_MEMORY=${SPARK_MEM}
  export SPARK_LOG_DIR=${SPARK_LOG_DIR}
  export SPARK_CONF_DIR=${SPARK_CONF_DIR}

  touch ${SPARK_CONF_DIR}/spark-env.sh
  chmod +x ${SPARK_CONF_DIR}/spark-env.sh

  echo "SPARK_WORKER_MEMORY=${SPARK_MEM}" >  ${SPARK_CONF_DIR}/spark-env.sh
  echo "SPARK_LOG_DIR=${SPARK_LOG_DIR}"   >> ${SPARK_CONF_DIR}/spark-env.sh
  echo "SPARK_CONF_DIR=${SPARK_CONF_DIR}" >> ${SPARK_CONF_DIR}/spark-env.sh
}

main() {
  if [[ "$SLURM_NODEID" == "0" ]]; then
    echo "$(hostname) is running the setup task"
    make::dirs
    env::rank "$SLURM_JOB_NODELIST"
    spark::env_config
  fi
}

main
