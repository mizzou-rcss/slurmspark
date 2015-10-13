#!/bin/bash - 
#===============================================================================
#
#          FILE: spark_run.sh
# 
#         USAGE: ./spark_run.sh 
# 
#   DESCRIPTION: Script that starts up the Spark cluster.
# 
#       OPTIONS: 
#  REQUIREMENTS: 
#          BUGS: Please Report
#         NOTES: 
#        AUTHOR: Micheal Quinn (), quinnm@missouri.edu
#  ORGANIZATION: RCSS
#       CREATED: 10/06/2015 04:19:52 PM CDT
#      REVISION: 0.1
#===============================================================================
set -o nounset                              # Treat unset variables as an error
source ${SCRIPT_HOME}/pre_setup.sh
source ${SCRIPT_HOME}/check_config.sh

#-------------------------------------------------------------------------------
# CONFIG
#-------------------------------------------------------------------------------
HOSTNAME="$(hostname -s)"

#-------------------------------------------------------------------------------
#  FUNCTIONS
#-------------------------------------------------------------------------------
#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  spark::start_master
#   DESCRIPTION:  Starts the spark master
#    PARAMETERS:  NONE
#       RETURNS:  NONE
#-------------------------------------------------------------------------------
spark::start_master() {
  ${SPARK_HOME}/sbin/spark-daemon.sh start org.apache.spark.deploy.master.Master 1 \
    --ip $SPARK_MASTER_IP \
    --port $SPARK_MASTER_PORT \
    --webui-port $SPARK_MASTER_WEBUI_PORT &>/dev/null
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  spark::start_slave
#   DESCRIPTION:  Starts a spark slave
#    PARAMETERS:  NONE
#       RETURNS:  NONE
#-------------------------------------------------------------------------------
spark::start_slave() {
  local spark_worker_cores="$1"

  SPARK_WORKER_CORES=${spark_worker_cores} ${SPARK_HOME}/sbin/spark-daemon.sh \
    start org.apache.spark.deploy.worker.Worker 1 \
    --webui-port ${SPARK_WORKER_WEBUI_PORT} \
    "spark://${SPARK_MASTER_IP}:${SPARK_MASTER_PORT}" &>/dev/null
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  spark::wait_for_master
#   DESCRIPTION:  Monitors for the master's log file, then watches log for
#                 signs of completion.
#    PARAMETERS:  NONE
#       RETURNS:  NONE
#-------------------------------------------------------------------------------
spark::wait_for_master() {
  local master_log="${SPARK_LOG_DIR}/*master.Master*.out"

  while true; do
    if grep -q "INFO Utils: Successfully started service 'sparkMaster' on port" $master_log 2>/dev/null; then
      break
    fi
    sleep 0.5
  done
  while true; do
    if grep -q "INFO Utils: Successfully started service on port" $master_log 2>/dev/null; then
      break
    fi
    sleep 0.5
  done
  while true; do
    if grep -q "INFO Utils: Successfully started service 'MasterUI' on port" $master_log 2>/dev/null; then
      break
    fi
    sleep 0.5
  done
  while true; do
    if grep -q "INFO MasterWebUI: Started MasterWebUI at" $master_log 2>/dev/null; then
      break
    fi
    sleep 0.5
  done
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  spark::get_set_info
#   DESCRIPTION:  Searches master's log for information on the spark cluster
#                 and sets / exports variables accordingly
#    PARAMETERS:  NONE
#       RETURNS:  NONE
#-------------------------------------------------------------------------------
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
  export SPARK_MASTER_WEBUI_PORT=${spark_ui_port}
  export SPARK_UI_URL=${spark_ui_url}
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  spark::print_info
#   DESCRIPTION:  Prints helpful info about the spark cluster
#    PARAMETERS:  NONE
#       RETURNS:  NONE
#-------------------------------------------------------------------------------
spark::print_info() {
  echo "#-------------------------------------------------------------------------------"
  echo "# SPARK MASTER INFO"
  echo "#-------------------------------------------------------------------------------"
  echo "            IP : ${SPARK_MASTER_IP}"
  echo "   Master Port : ${SPARK_MASTER_PORT}"
  echo "  Service Port : ${SPARK_SERVICE_PORT}"
  echo "    WebUI Port : ${SPARK_MASTER_WEBUI_PORT}"
  echo "     WebUI URL : ${SPARK_UI_URL}"
  echo "#-------------------------------------------------------------------------------"
  echo ""
  echo "#-------------------------------------------------------------------------------"
  echo "# SPARK SHELL INFO"
  echo "#-------------------------------------------------------------------------------"
  echo "Starting a Spark Shell:"
  echo "  MASTER=\"spark://${SPARK_MASTER_IP}:${SPARK_MASTER_PORT}\" ${SPARK_HOME}/bin/spark-shell"
  echo "#-------------------------------------------------------------------------------"
  echo ""
  echo "#-------------------------------------------------------------------------------"
  echo "# SPARK EXAMPLE JOB"
  echo "#-------------------------------------------------------------------------------"
  echo "Calculating Pi"
  echo "  export MASTER=\"spark://${SPARK_MASTER_IP}:${SPARK_MASTER_PORT}\""
  echo "  export SPARK_EXECUTOR_MEMORY=\"5g\""
  echo "  export SPARK_LOCAL_DIRS=\"${SPARK_LOCAL_DIRS}\""
  echo "  ${SPARK_HOME}/bin/run-example \"org.apache.spark.examples.SparkPi\" \"2\""
  echo "#-------------------------------------------------------------------------------"
  echo ""
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  spark::print_debug
#   DESCRIPTION:  Prints extra info about the environemnt. Currently unused.
#    PARAMETERS:  NONE
#       RETURNS:  NONE
#-------------------------------------------------------------------------------
spark::print_debug() {
  echo "#-------------------------------------------------------------------------------"
  echo "# DEBUG"
  echo "#-------------------------------------------------------------------------------"
  echo "Java Home          = ${JAVA_HOME}"
  echo ""
  echo "Spark Home         = ${SPARK_HOME}"
  echo "Spark Log Dir      = ${SPARK_LOG_DIR}"
  echo "Spark Conf Dir     = ${SPARK_CONF_DIR}"
  echo "Spark Pid Dir      = ${SPARK_PID_DIR}"
  echo "Spark Local Dir    = ${SPARK_LOCAL_DIRS}"
  echo "Spark Worker Dir   = ${SPARK_WORKER_DIR}"
  echo ""
  echo "Slurm CPUs in Node = ${SLURM_CPUS_ON_NODE}"
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  main
#   DESCRIPTION:  The main function.  It's task is to logically call out other
#                 functions in a logical order logically.
#    PARAMETERS:  NONE
#       RETURNS:  NONE
#-------------------------------------------------------------------------------
main() {
  local wait_time="$(slurm::walltime_to_min "$SLURM_WALLTIME")"

  if grep -q ${HOSTNAME} ${SPARK_CONF_DIR}/masters; then
    spark::start_master
    spark::wait_for_master
    spark::get_set_info
    spark::start_slave "$((${SPARK_WORKER_CORES} - 1))"
    spark::print_info
  else
    spark::wait_for_master
    spark::get_set_info
    spark::start_slave "${SPARK_WORKER_CORES}"
  fi

  ## For Debugging
  env > ${SPARK_LOG_DIR}/$(hostname).run.env

  ## Wait for timeout
  slurm::wait "$wait_time"
}

#-------------------------------------------------------------------------------
#  CALL
#-------------------------------------------------------------------------------
main
