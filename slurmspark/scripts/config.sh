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
# SCRIPT CONFIG
#-------------------------------------------------------------------------------
JAVA_HOME="/usr/lib/jvm/java-1.7.0"
SSH_OPTS="-o StrictHostKeyChecking=no"

SLURM_WALLTIME="$(squeue -j ${SLURM_JOB_ID} -h -o %L)"

SPARK_NODE_RANK="$SLURM_NODEID"
SPARK_VERSION="1.4.1-hadoop2.6"
SPARK_HOME="${HOME}/spark/spark-${SPARK_VERSION}"
SPARK_LOG_DIR="${SPARK_HOME}/logs/${SLURM_JOB_ID}"
SPARK_CONF_DIR="${SPARK_HOME}/conf/${SLURM_JOB_ID}"
SPARK_PID_DIR="${SPARK_HOME}/pid/${SLURM_JOB_ID}"
SPARK_MEM=$(scontrol show jobid $SLURM_JOB_ID | grep Memory | awk '{print $2}' | awk -F"=" '{print $2}')
