#!/bin/bash - 
#===============================================================================
#
#          FILE: config.sh
# 
#         USAGE: ./config.sh 
# 
#   DESCRIPTION: Configuration file for use with the slurmspark project
# 
#       OPTIONS: 
#  REQUIREMENTS: 
#          BUGS: Please Report
#         NOTES: 
#        AUTHOR: Micheal Quinn (), quinnm@missouri.edu
#  ORGANIZATION: RCSS
#       CREATED: 10/06/2015 03:54:47 PM CDT
#      REVISION: 1.0
#===============================================================================
set -o nounset                              # Treat unset variables as an error

#-------------------------------------------------------------------------------
# CONFIG (Modifiable)
#-------------------------------------------------------------------------------
## Directory for shared scratch.
##     Notes: Directory must be accessible from every node in the cluster
##            This directory will contain your job-specific spark configs, logs, etc...
SCRATCH_DIR="${HOME}/sparkscratch"

## Directory for non-shared scratch (local to nodes).
LOCAL_SCRATCH_DIR="/local/scratch/${USER}"

## Java home directory
JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.71-2.b15.el7_2.x86_64/jre"

## TO DO
## Java version to use via Environment Modules
#JAVA_MODULE="java/openjdk/java-1.8.0-openjdk"

## Spark Binary Prefix
##   Options: Valid path to a directory containing spark installs
##     Notes: To use the system's version of spark, set this to
##            SPARK_HOME_PREFIX="/cluster/software/spark"
##
##            To use a custom install, specify a path to your spark installs.
##            Example: SPARK_HOME_PREFIX="${HOME}/spark"
##              Where ${HOME}/spark contains your spark versions
##              ${HOME}/spark
##              ├── spark-1.4.1-bin-hadoop2.6
##              │   ├── bin
##              │   ├── CHANGES.txt
##              │   ├── conf
##              │   ├── data
##              │   ├── ec2
##              │   ├── examples
##              │   ├── lib
##              │   ├── LICENSE
##              │   ├── NOTICE
##              │   ├── python
##              │   ├── R
##              │   ├── README.md
##              │   ├── RELEASE
##              │   └── sbin
##              └── spark-1.5.1-bin-hadoop2.6
##                  ├── bin
##                  ├── CHANGES.txt
##                  ├── conf
##                  ├── data
##                  ├── ec2
##                  ├── examples
##                  ├── lib
##                  ├── LICENSE
##                  ├── NOTICE
##                  ├── python
##                  ├── R
##                  ├── README.md
##                  ├── RELEASE
##                  └── sbin
##
##             You can download spark from http://spark.apache.org/downloads.html
SPARK_BINARY_PREFIX="/cluster/software/spark"

## TO DO
## Spark version to use via Environment Modules
#SPARK_MODULE="spark/spark-1.6.0-hadoop2.6"


## Spark and Hadoop Version to use
##   Options: When using system's install, these values must match what a version
##            That is currently installed in /share/sw/spark
##     Notes: These two values (along with SPARK_BINARY_PREFIX) are joined later in this file and the result is 
##            stored in SPARK_HOME.
##
##            For example, if 
##              SPARK_BINARY_PREFIX=/cluster/software/spark
##              SPARK_VERSION=1.4.1-bin
##              SPARK_HADOOP_VERSION=2.6
##            then
##              SPARK_HOME=/cluster/software/spark-1.4.1-bin-hadoop2.6
##               
##
SPARK_VERSION="1.6.0-bin"
SPARK_HADOOP_VERSION="2.6"

## Directory to write spark ( logs | configuration file | pids | local ) to.
##   Options: Valid path to directory shared between nodes
##     Notes: Needs to be writable by your user.
##
SPARK_LOG_DIR="${SCRATCH_DIR}/logs/spark/${SLURM_JOB_ID}"
SPARK_CONF_DIR="${SCRATCH_DIR}/conf/spark/${SLURM_JOB_ID}"
SPARK_PID_DIR="${SCRATCH_DIR}/pid/spark/${SLURM_JOB_ID}"
SPARK_LOCAL_DIRS="${LOCAL_SCRATCH_DIR}/local/sprak/${SLURM_JOB_ID}"
SPARK_WORKER_DIR="${LOCAL_SCRATCH_DIR}/worker/spark/${SLURM_JOB_ID}"

## Spark ( MASTER | MASTER_WEBUI | WORKER_WEBUI ) Port
##   Options: (any port greater than 1000 that is not in use)
##     Notes: The default is fine.  Spark will automatcially attempt
##            to bind to a new port if 7077 is in use.
##
##            This will most likely be the case as there may be many other
##            users attempting to Spark the same time you are.
##
##            After the deamons start up, your job output file will notify you
##            of the 'true' ports your Spark cluster is using.
SPARK_MASTER_PORT="7077"
SPARK_MASTER_WEBUI_PORT="8080"
SPARK_WORKER_WEBUI_PORT="8081"

#-------------------------------------------------------------------------------
#  DEPRECATED CONFIG HADOOP
#-------------------------------------------------------------------------------
## Hadoop Setup
##    Options: true or false
##             If true, set up an hdfs cluster along with the spark cluster
##             If false, only setup a spark cluster
HADOOP_SP_SETUP="false"

## Initial port to attempt to bind hadoop to
HADOOP_PORT="9090"

## Version of haddoop to use
HADOOP_VERSION="2.6.1"

## Directories to store Hadoop logs, pids, and conf
HADOOP_LOG_DIR="${SCRATCH_DIR}/logs/hadoop/${SLURM_JOB_ID}"
HADOOP_PID_DIR="${SCRATCH_DIR}/pid/hadoop/${SLURM_JOB_ID}"
HADOOP_CONF_DIR="${SCRATCH_DIR}/conf/hadoop/${SLURM_JOB_ID}"

## Location of the hadoop binaries.  Similar logic to SPARK_BINARY_PREFIX
HADOOP_BINARY_PREFIX="/share/sw/hadoop"

## Full path to hadoop install based on the HADOOP_BINARY_PREFIX setting
HADOOP_PREFIX="${HADOOP_BINARY_PREFIX}/hadoop-${HADOOP_VERSION}"

## Currently unused
HADOOP_COMMON="${HADOOP_BINARY_PREFIX}/hadoop-${HADOOP_VERSION}"
HADOOP_HDFS_HOME="/local/scratch/${USER}/hadoop/${SLURM_JOB_ID}"
HADOOP_MAPRED_HOME="/local/scratch/${USER}/hadoop/${SLURM_JOB_ID}"
HADOOP_YARN_HOME="/local/scratch/${USER}/hadoop/${SLURM_JOB_ID}"
HADOOP_COMMON_LIB_NATIVE_DIR="${HADOOP_PREFIX}/lib/native"
HADOOP_OPTS="-Djava.library.path=${HADOOP_PREFIX}/lib"

#-------------------------------------------------------------------------------
# CONFIG (should not need to modify)
#-------------------------------------------------------------------------------
## Hostname of system this script is run on
HOSTNAME="$(hostname -s)"

## Determine the walltime of the job.  This is used to determine how long 
## spark-run.sh will wait before exiting.
SLURM_WALLTIME="$(squeue -j ${SLURM_JOB_ID} -h -o %L)"

## Currently Unused
#SPARK_NODE_RANK="$SLURM_NODEID"

## SSH Options
SSH_OPTS="-o StrictHostKeyChecking=no"

## Directory of the Spark install to use
SPARK_HOME="${SPARK_BINARY_PREFIX}/spark-${SPARK_VERSION}-hadoop${SPARK_HADOOP_VERSION}"

## Determine the memory to set workers to based on Slurm job
SPARK_WORKER_MEMORY="$(scontrol show jobid $SLURM_JOB_ID | grep -oE 'MinMemory(Node|CPU)=[0-9]*[a-zA-Z]' | awk -F'=' '{print $2}')"

## Determine number of CPUs to use for the workers based on Slurm job
SPARK_WORKER_CORES="${SLURM_CPUS_ON_NODE}"
