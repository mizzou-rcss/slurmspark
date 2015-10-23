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
#      REVISION: 1.0
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
#          NAME:  hadoop::choose_port
#   DESCRIPTION:  Based on the port supplied, check to ensure it is not already
#                 in use.  If it is, add 1 to port and try again.
#    PARAMETERS:  $1 : port
#       RETURNS:  Echos port
#-------------------------------------------------------------------------------
hadoop::choose_port() {
  local port="$1"

	while true; do
		ports="$(netstat -lnt |tail -n+3 | awk '{print $4}' | grep -o ':[0-9].*' | sed 's/\://g' | sort | uniq)"
		check="$(echo "$ports" | grep "$port")"

		if [[ "$check" != "" ]]; then
			port=$((port+1))
		else
			break
		fi
		sleep 1
	done
  echo "$port"
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  hadoop::config
#   DESCRIPTION:  Writes the core-site.xml file using supplied node and port 
#    PARAMETERS:  $1 : node to be the hdfs master
#                 $2 : port to listen on
#       RETURNS:  NONE
#-------------------------------------------------------------------------------
hadoop::config() {
  local node="$1"
  local port="$2"
  local hdfs="hdfs://${node}:${port}/"

  cp -R ${HADOOP_PREFIX}/etc/hadoop/* ${HADOOP_CONF_DIR}/

  echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>${hdfs}</value>
    </property>
</configuration>" > ${HADOOP_CONF_DIR}/core-site.xml
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  hadoop::wait_for_config
#   DESCRIPTION:  Wait for the slurmspark modified core-site.xml to be populated
#    PARAMETERS:  NONE
#       RETURNS:  NONE
#-------------------------------------------------------------------------------
hadoop::wait_for_config() {
  local config="${HADOOP_CONF_DIR}/core-site.xml"

  while true; do
    if grep -q "fs.defaultFS" $config 2>/dev/null; then
      break
    fi
    sleep 0.5
  done
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  hadoop::start_master
#   DESCRIPTION:  Start the hdfs master
#    PARAMETERS:  NONE
#       RETURNS:  NONE
#-------------------------------------------------------------------------------
hadoop::start_master() {
  env > ${HADOOP_LOG_DIR}/$(hostname).run.env
  ${HADOOP_PREFIX}/bin/hdfs namenode -format -force &>${HADOOP_LOG_DIR}/${HOSTNAME}_master_format.log
  ${HADOOP_PREFIX}/bin/hdfs namenode &>${HADOOP_LOG_DIR}/${HOSTNAME}_master.log &
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  hadoop::start_slave
#   DESCRIPTION:  Start the hdfs slave
#    PARAMETERS:  NONE
#       RETURNS:  NONE
#-------------------------------------------------------------------------------
hadoop::start_slave() {
  local hdfs="$(sed -e 's/<[^>]*>//g' ${HADOOP_CONF_DIR}/core-site.xml | grep -o 'hdfs.*')"
 
  ${HADOOP_PREFIX}/bin/hdfs datanode -fs ${hdfs} &>${HADOOP_LOG_DIR}/${HOSTNAME}_slave.log &
}

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
    --webui-port $SPARK_MASTER_WEBUI_PORT &>/dev/null &
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
    "spark://${SPARK_MASTER_IP}:${SPARK_MASTER_PORT}" &>/dev/null &
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
    if grep -q "Successfully started service 'sparkMaster' on port" $master_log 2>/dev/null; then
      break
    fi
    sleep 0.5
  done
  while true; do
    if grep -q "Successfully started service on port" $master_log 2>/dev/null; then
      break
    fi
    sleep 0.5
  done
  while true; do
    if grep -q "Successfully started service 'MasterUI' on port" $master_log 2>/dev/null; then
      break
    fi
    sleep 0.5
  done
  while true; do
    if grep -q "Started MasterWebUI at" $master_log 2>/dev/null; then
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

  local spark_master_port=$(grep "Successfully started service 'sparkMaster' on port" $master_log \
                            | awk -F 'port ' '{print $2}' | sed 's/\.$//g')
  local spark_service_port=$(grep "Successfully started service on port" $master_log \
                             | awk -F 'port ' '{print $2}' | sed 's/\.$//g')
  local spark_ui_port=$(grep "Successfully started service 'MasterUI' on port" $master_log \
                        | awk -F 'port ' '{print $2}' | sed 's/\.$//g')
  local spark_ui_url=$(grep "Started MasterWebUI at" $master_log \
                       | grep -iIohE 'https?://[^[:space:]]+')
  local hdfs=$(sed -e 's/<[^>]*>//g' ${HADOOP_CONF_DIR}/core-site.xml | grep -o 'hdfs.*')
  local hdfs_web_port=$(grep "Starting Web-server for hdfs at:" ${HADOOP_LOG_DIR}/${spark_master_ip}_master.log \
                        | grep -o "http.*" | awk -F\: '{print $3}')
  local hdfs_web_url="http://${spark_master_ip}:${hdfs_web_port}/"

  export SPARK_MASTER_IP=${spark_master_ip}
  export SPARK_MASTER_PORT=${spark_master_port}
  export SPARK_SERVICE_PORT=${spark_service_port}
  export SPARK_MASTER_WEBUI_PORT=${spark_ui_port}
  export SPARK_UI_URL=${spark_ui_url}
  export HDFS_LOCATION=${hdfs}
  export HDFS_WEB_URL=${hdfs_web_url}
  
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
  echo "#-------------------------------------------------------------------------------"
  echo "# HDFS INFO"
  echo "#-------------------------------------------------------------------------------"
  echo "    Location : ${HDFS_LOCATION}"
  echo "   WebUI URL : ${HDFS_WEB_URL}"
  echo "#-------------------------------------------------------------------------------"
  echo ""
  echo "#-------------------------------------------------------------------------------"
  echo "# HDFS EXAMPLE"
  echo "#-------------------------------------------------------------------------------"
  echo "export JAVA_HOME=${JAVA_HOME}"
  echo "export HADOOP_PREFIX=${HADOOP_PREFIX}"
  echo "export PATH=${HADOOP_PREFIX}/bin:\$PATH"
  echo "export HADOOP_CONF_DIR=${HADOOP_CONF_DIR}"
  echo "hadoop fs -mkdir /test1"
  echo "hadoop fs -ls /"
  echo "#-------------------------------------------------------------------------------"
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
  ## Set the wait_time to determined wall time
  local wait_time="$(slurm::walltime_to_min "$SLURM_WALLTIME")"

  ## If we are the 'master' node, start master services
  if grep -q ${HOSTNAME} ${SPARK_CONF_DIR}/masters; then
    ## Ensure our hadoop port is not in use
    local hadoop_port="$(hadoop::choose_port "${HADOOP_PORT}")"
    ## Set the core-site.xml for our hdfs cluster
    hadoop::config "${HOSTNAME}" "${hadoop_port}"
    ## Start the hdfs master
    hadoop::start_master

    ## Start the master Spark service
    spark::start_master
    ## Wait for the service to be up
    spark::wait_for_master
    ## Get and export service info for use in info messages etc..
    spark::get_set_info
    ## Start the slave, using one less core than allocated
    spark::start_slave "$((${SPARK_WORKER_CORES} - 1))"
    ## Print info on the cluster
    spark::print_info
  ## If we are not the master node, start slave services
  else
    ## Wait for the core-site.xml to be written
    hadoop::wait_for_config
    ## Start the hdfs slaves
    hadoop::start_slave
    
    ## Wait for the Spark master to start on the master node 
    spark::wait_for_master
    ## Get and export service info for use in info messages etc..
    spark::get_set_info
    ## Start the slave
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
