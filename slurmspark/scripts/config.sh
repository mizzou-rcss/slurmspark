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
## Java Version to use
##   Options: 1.7.0
##            1.8.0
JAVA_VERSION="1.7.0"

## Spark Binary Prefix
##   Options: Valid path to a directory containing spark installs
##     Notes: To use the system's version of spark, set this to
##            SPARK_HOME_PREFIX="/share/sw/spark"
##
##            To use a custom install, specify any complete and valid path.
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
SPARK_BINARY_PREFIX="${HOME}/spark"

##
SPARK_SCRATCH_DIR="${HOME}/sparkscratch"

## Spark Version to use
##   Options: When using system's install
##              1.4.1-hadoop2.6
##              MORE SOON!!
##
SPARK_VERSION="1.4.1-bin-hadoop2.6"

## Directory to write spark ( logs | configuration file | pids ) to.
##   Options: Valid path to directory shared between nodes
##     Notes: Needs to be writable by your user.
##
SPARK_LOG_DIR="${SPARK_SCRATCH_DIR}/logs/${SLURM_JOB_ID}"
SPARK_CONF_DIR="${SPARK_SCRATCH_DIR}/conf/${SLURM_JOB_ID}"
SPARK_PID_DIR="${SPARK_SCRATCH_DIR}/pid/${SLURM_JOB_ID}"

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
# CONFIG (DO NOT MODIFY!!)
#-------------------------------------------------------------------------------
## Hostname of system this script is run on
HOSTNAME="$(hostname -s)"

## Java home directory.  Uses JAVA_VERSION set above.
JAVA_HOME="/usr/lib/jvm/java-${JAVA_VERSION}"

## Determine the walltime of the job.  This is used to determine how long 
## spark-run.sh will wait before exiting.
SLURM_WALLTIME="$(squeue -j ${SLURM_JOB_ID} -h -o %L)"

## Currently Unused
#SPARK_NODE_RANK="$SLURM_NODEID"

## Directory of the Spark install to use
SPARK_HOME="${SPARK_BINARY_PREFIX}/spark-${SPARK_VERSION}"

##
SPARK_WORKER_MEMORY=$(scontrol show jobid $SLURM_JOB_ID | grep -oE 'MinMemory(Node|CPU)=[0-9]*[a-zA-Z]' | awk -F'=' '{print $2}')

##
SPARK_WORKER_CORES=$(scontrol show jobid $SLURM_JOB_ID | grep -oE 'NumCPUs=[0-9]*' | grep -oE '[0-9]*')
