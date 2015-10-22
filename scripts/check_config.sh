#!/bin/bash - 
#===============================================================================
#
#          FILE: check_config.sh
# 
#         USAGE: ./check_config.sh 
# 
#   DESCRIPTION: Script to validate values from config.sh
# 
#       OPTIONS: NONE
#  REQUIREMENTS: 
#          BUGS: Please Report
#         NOTES: 
#        AUTHOR: Micheal Quinn (), quinnm@missouri.edu
#  ORGANIZATION: RCSS
#       CREATED: 10/08/2015 09:28:19 AM CDT
#      REVISION: 0.1
#===============================================================================
set -o nounset                              # Treat unset variables as an error
source ${SCRIPT_HOME}/config.sh

#-------------------------------------------------------------------------------
#  CONFIG
#-------------------------------------------------------------------------------
HOSTNAME="$(hostname -s)"

#-------------------------------------------------------------------------------
#  FUNCTIONS
#-------------------------------------------------------------------------------
#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  print::message
#   DESCRIPTION:  Prints a message to stdout
#    PARAMETERS:  $1 = Message type.  One of INFO, WARN, or ERROR
#                 $2 = Message.
#       RETURNS:  0 = OK
#                 1 = Fail (and exit)
#-------------------------------------------------------------------------------
print::message() {
  local message_type="$1"
  local message="$2"
  
  case "$message_type" in
    'INFO'  ) echo "$HOSTNAME : $message_type : $message"
              ;;
    'WARN'  ) echo "$HOSTNAME : $message_type : $message"
              ;;
    'ERROR' ) echo "$HOSTNAME : $message_type : $message";
              exit 1;
              ;;
  esac
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  check::variables
#   DESCRIPTION:  Checks each variable defined in config.sh.
#                 
#                 Currently, each check is 'hard coded'.  May rewrite
#                 to be more dynamic.  That is, if config.sh is extedned with a
#                 new variable, check_config.sh should not need an update.
#    PARAMETERS:  NONE
#       RETURNS:  NONE
#-------------------------------------------------------------------------------
check::variables() {
  ## JAVA_VERSION
  if [[ "$JAVA_VERSION" == "" ]]; then
    print::message "ERROR" "JAVA_VERSION must be set"
  fi

  ## SPARK_BINARY_PREFIX
  if [[ "$SPARK_BINARY_PREFIX" == "" ]]; then
    print::message "ERROR" "SPARK_BINARY_PREFIX must be set"
  fi
  if [[ ! -d "$SPARK_BINARY_PREFIX" ]]; then
    print::message "ERROR" "SPARK_BINARY_PREFIX must be a directory"
  fi

  ## SCRATCH_DIR
  if [[ "$SCRATCH_DIR" == "" ]]; then
    print::message "ERROR" "SCRATCH_DIR must be set"
  fi
  if [[ ! -d "$SCRATCH_DIR" ]]; then
    print::message "ERROR" "SCRATCH_DIR must be a directory"
  fi

  ## SPARK_VERSION
  if [[ "$SPARK_VERSION" == "" ]]; then
    print::message "ERROR" "SPARK_VERSION must be set"
  fi

  ## SPARK_HADOOP_VERSION
  if [[ "$SPARK_HADOOP_VERSION" == "" ]]; then
    print::message "ERROR" "SPARK_HADOOP_VERSION must be set"
  fi

  ## SPARK_LOG_DIR
  if [[ "$SPARK_LOG_DIR" == "" ]]; then
    print::message "ERROR" "SPARK_LOG_DIR must be set"
  fi
  if [[ ! -d "$SPARK_LOG_DIR" ]]; then
    print::message "ERROR" "SPARK_LOG_DIR must be a directory"
  fi

  ## SPARK_CONF_DIR
  if [[ "$SPARK_CONF_DIR" == "" ]]; then
    print::message "ERROR" "SPARK_CONF_DIR must be set"
  fi
  if [[ ! -d "$SPARK_CONF_DIR" ]]; then
    print::message "ERROR" "SPARK_CONF_DIR must be a directory"
  fi

  ## SPARK_PID_DIR
  if [[ "$SPARK_PID_DIR" == "" ]]; then
    print::message "ERROR" "SPARK_PID_DIR must be set"
  fi
  if [[ ! -d "$SPARK_PID_DIR" ]]; then
    print::message "ERROR" "SPARK_PID_DIR must be a directory"
  fi

  ## SPARK_LOCAL_DIRS
  if [[ "$SPARK_LOCAL_DIRS" == "" ]]; then
    print::message "ERROR" "SPARK_LOCAL_DIRS must be set"
  fi
  if [[ ! -d "$SPARK_LOCAL_DIRS" ]]; then
    print::message "ERROR" "SPARK_LOCAL_DIRS must be a directory"
  fi

  ## SPARK_WORKER_DIR
  if [[ "$SPARK_WORKER_DIR" == "" ]]; then
    print::message "ERROR" "SPARK_WORKER_DIR must be set"
  fi
  if [[ ! -d "$SPARK_WORKER_DIR" ]]; then
    print::message "ERROR" "SPARK_WORKER_DIR must be a directory"
  fi

  ## SPARK_MASTER_PORT
  if [[ "$SPARK_MASTER_PORT" == "" ]]; then
    print::message "ERROR" "SPARK_MASTER_PORT must be set"
  fi

  ## SPARK_MASTER_WEBUI_PORT
  if [[ "$SPARK_MASTER_WEBUI_PORT" == "" ]]; then
    print::message "ERROR" "SPARK_MASTER_WEBUI_PORT must be set"
  fi

  ## SPARK_WORKER_WEBUI_PORT
  if [[ "$SPARK_WORKER_WEBUI_PORT" == "" ]]; then
    print::message "ERROR" "SPARK_WORKER_WEBUI_PORT must be set"
  fi

  ## HOSTNAME
  if [[ "$HOSTNAME" == "" ]]; then
    print::message "ERROR" "HOSTNAME must be set"
  fi

  ## JAVA_HOME
  if [[ "$JAVA_HOME" == "" ]]; then
    print::message "ERROR" "JAVA_HOME must be set"
  fi
  if [[ ! -d "$JAVA_HOME" ]]; then
    print::message "ERROR" "JAVA_HOME must be a directory"
  fi

  ## SLURM_WALLTIME
  if [[ "$SLURM_WALLTIME" == "" ]]; then
    print::message "ERROR" "SLURM_WALLTIME must be set"
  fi

  ## SSH_OPTS
  if [[ "$SSH_OPTS" == "" ]]; then
    print::message "ERROR" "SSH_OPTS must be set"
  fi

  ## SPARK_HOME
  if [[ "$SPARK_HOME" == "" ]]; then
    print::message "ERROR" "SPARK_HOME must be set"
  fi
  if [[ ! -d "$SPARK_HOME" ]]; then
    print::message "ERROR" "SPARK_HOME must be a directory"
  fi

  ## SPARK_WORKER_MEMORY
  if [[ "$SPARK_WORKER_MEMORY" == "" ]]; then
    print::message "ERROR" "SPARK_WORKER_MEMORY must be set"
  fi

  ## SPARK_WORKER_CORES
  if [[ "$SPARK_WORKER_CORES" == "" ]]; then
    print::message "ERROR" "SPARK_WORKER_CORES must be set"
  fi
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  main
#   DESCRIPTION:  The main function.  It's task is to logically call out other
#                 functions in a logical order logically.
#    PARAMETERS:  NONE
#       RETURNS:  NONE
#-------------------------------------------------------------------------------
main() {
  check::variables
}

#-------------------------------------------------------------------------------
#  CALL
#-------------------------------------------------------------------------------
main
