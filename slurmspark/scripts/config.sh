#!/bin/bash - 
#===============================================================================
#
#          FILE: config.sh
# 
#         USAGE: ./config.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Micheal Quinn (), quinnm@missouri.edu
#  ORGANIZATION: 
#       CREATED: 10/06/2015 03:54:47 PM CDT
#      REVISION:  ---
#===============================================================================
#-------------------------------------------------------------------------------
# CONFIG (Modifiable)
#-------------------------------------------------------------------------------
JAVA_HOME="/usr/lib/jvm/java-1.7.0"
SSH_OPTS="-o StrictHostKeyChecking=no"
SPARK_VERSION="1.4.1-hadoop2.6"
SPARK_MASTER_PORT="7077"
SPARK_MASTER_WEBUI_PORT="8080"
SPARK_WORKER_WEBUI_PORT="8081"

#-------------------------------------------------------------------------------
# CONFIG (DO NOT MODIFY!!)
#-------------------------------------------------------------------------------
HOSTNAME="$(hostname -s)"
SLURM_WALLTIME="$(squeue -j ${SLURM_JOB_ID} -h -o %L)"
SPARK_NODE_RANK="$SLURM_NODEID"
SPARK_HOME="${HOME}/spark/spark-${SPARK_VERSION}"
SPARK_LOG_DIR="${SPARK_HOME}/logs/${SLURM_JOB_ID}"
SPARK_CONF_DIR="${SPARK_HOME}/conf/${SLURM_JOB_ID}"
SPARK_PID_DIR="${SPARK_HOME}/pid/${SLURM_JOB_ID}"
SPARK_WORKER_MEMORY=$(scontrol show jobid $SLURM_JOB_ID | grep -oE 'MinMemory(Node|CPU)=[0-9]*[a-zA-Z]' | awk -F'=' '{print $2}')
SPARK_WORKER_CORES=$(scontrol show jobid $SLURM_JOB_ID | grep -oE 'NumCPUs=[0-9]*' | grep -oE '[0-9]*')
