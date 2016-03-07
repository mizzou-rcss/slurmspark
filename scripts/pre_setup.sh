#!/bin/bash - 
#===============================================================================
#
#          FILE: pre_setup.sh
# 
#         USAGE: ./pre_setup.sh 
# 
#   DESCRIPTION: Sets up the environent for the slurmspark job
# 
#       OPTIONS: 
#  REQUIREMENTS: 
#          BUGS: Please Report
#         NOTES: 
#        AUTHOR: Micheal Quinn (), quinnm@missouri.edu
#  ORGANIZATION: RCSS
#       CREATED: 10/06/2015 03:57:31 PM CDT
#      REVISION: 1.5
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
#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  make::dirs
#   DESCRIPTION:  Makes required directories for the slurmspark job
#    PARAMETERS:  NONE
#       RETURNS:  NONE
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
  if [[ ! -d ${SPARK_LOCAL_DIRS} ]]; then
    mkdir -p ${SPARK_LOCAL_DIRS}
  fi
  if [[ ! -d ${SPARK_WORKER_DIR} ]]; then
    mkdir -p ${SPARK_WORKER_DIR}
  fi
  if [[ ! -d ${HADOOP_CONF_DIR} ]]; then
    mkdir -p ${HADOOP_CONF_DIR}
  fi
  if [[ ! -d ${HADOOP_HDFS_HOME} ]]; then
    mkdir -p ${HADOOP_HDFS_HOME}
    ln -snf ${HADOOP_HDFS_HOME} /tmp/hadoop-${USER}
  fi
  if [[ ! -d ${HADOOP_MAPRED_HOME} ]]; then
    mkdir -p ${HADOOP_MAPRED_HOME}
  fi
  if [[ ! -d ${HADOOP_YARN_HOME} ]]; then
    mkdir -p ${HADOOP_YARN_HOME}
  fi
  if [[ ! -d ${HADOOP_LOG_DIR} ]]; then
    mkdir -p ${HADOOP_LOG_DIR}
  fi
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  spark::set_rank
#   DESCRIPTION:  Ranks nodes in job based on hostname order, and writes
#                 config files if write_config=true
#    PARAMETERS:  $1 = List of nodes, usually from $SLURM_JOB_NODELIST
#       RETURNS:  NONE
#-------------------------------------------------------------------------------
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

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  spark::env_config
#   DESCRIPTION:  Writes out useful Slurm environemtnal variables to 
#                 ${SPARK_CONF_DIR}/spark-env.sh
#
#                 Currently unused.
#    PARAMETERS:  NONE
#       RETURNS:  NONE
#-------------------------------------------------------------------------------
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

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  spark::env_export
#   DESCRIPTION:  Exports Slurm environemtnal variables
#    PARAMETERS:  NONE
#       RETURNS:  NONE
#-------------------------------------------------------------------------------
spark::env_export() {
  export JAVA_HOME=${JAVA_HOME}
  PATH=${JAVA_HOME}:${PATH}
  export PATH=${PATH}

  export SPARK_LOG_DIR=${SPARK_LOG_DIR}
  export SPARK_CONF_DIR=${SPARK_CONF_DIR}
  export SPARK_MASTER_IP=${SPARK_MASTER_IP}
  export SPARK_MASTER_PORT=${SPARK_MASTER_PORT}
  export SPARK_MASTER_WEBUI_PORT=${SPARK_MASTER_WEBUI_PORT}
  export SPARK_WORKER_CORES=${SPARK_WORKER_CORES}
  export SPARK_WORKER_MEMORY=${SPARK_WORKER_MEMORY}
  export SPARK_LOCAL_DIRS=${SPARK_LOCAL_DIRS}
  export SPARK_WORKER_DIR=${SPARK_WORKER_DIR}
  export HADOOP_PREFIX=${HADOOP_PREFIX}
  export HADOOP_CONF_DIR=${HADOOP_CONF_DIR}
  export HADOOP_PID_DIR=${HADOOP_PID_DIR}
  export HADOOP_LOG_DIR=${HADOOP_LOG_DIR}
  #export HADOOP_COMMON=${HADOOP_COMMON}
  #export HADOOP_HDFS_HOME=${HADOOP_HDFS_HOME}
  #export HADOOP_MAPRED_HOME=${HADOOP_MAPRED_HOME}
  #export HADOOP_YARN_HOME=${HADOOP_YARN_HOME}
  #export HADOOP_COMMON_LIB_NATIVE_DIR=${HADOOP_COMMON_LIB_NATIVE_DIR}
  #export HADOOP_OPTS=${HADOOP_OPTS}
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  main
#   DESCRIPTION:  The main function.  It's task is to logically call out other
#                 functions in a logical order logically.
#    PARAMETERS:  NONE
#       RETURNS:  NONE
#-------------------------------------------------------------------------------
main() {
  make::dirs
  
  if [[ "$SLURM_NODEID" == "0" ]]; then
    spark::set_rank "$SLURM_JOB_NODELIST" "true"
  else
    spark::set_rank "$SLURM_JOB_NODELIST" "false"
  fi
  
  spark::env_export

  ## For Debugging
  env > ${SPARK_LOG_DIR}/$(hostname).pre.env
}

#-------------------------------------------------------------------------------
#  CALL
#-------------------------------------------------------------------------------
main
