#!/bin/bash - 
#===============================================================================
#
#          FILE: slurmspark.sh
# 
#         USAGE: ./slurmspark.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Micheal Quinn (), quinnm@missouri.edu
#  ORGANIZATION: 
#       CREATED: 10/05/2015 10:49:33 AM CDT
#      REVISION:  ---
#===============================================================================
#-------------------------------------------------------------------------------
#  SBATCH CONFIG
#-------------------------------------------------------------------------------
#SBATCH --nodes=3
#SBATCH --output="slurm-spark-%j.out"
#SBATCH --time=128
#SBATCH --job-name=testing
#SBATCH --partition=Mem128

#SBATCH --ntasks-per-node=1
#SBATCH --exclusive
#SBATCH --no-kill

#-------------------------------------------------------------------------------
#  CONFIG
#-------------------------------------------------------------------------------
LOCAL_PREFIX="/local/scratch"

NODES="$SLURM_JOB_NODELIST"
JOB_MEM=$(scontrol show jobid $SLURM_JOB_ID | grep Memory | awk '{print $2}' | awk -F"=" '{print $2}')

SPARK_VERSION="1.4.1-hadoop2.6"
SPARK_HOME="${HOME}/spark/spark-${SPARK_VERSION}"

JAVA_HOME="/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.79-2.5.5.1.el7_1.x86_64/"

SSH_OPTS="-o StrictHostKeyChecking=no"

#-------------------------------------------------------------------------------
#  FUNCTIONS
#-------------------------------------------------------------------------------
expand::nodelist() {
  local nodelist="$1"

  scontrol show hostnames "$nodelist" | paste -s -d " "
}

conf::set_master() {
  local master_node="$1"

  echo "$master_node" > $SPARK_HOME/conf/masters
}

conf::set_slaves() {
  local slave_nodes="$1"

  rm -f $SPARK_HOME/conf/slaves

  for i in $slave_nodes; do
    echo "$i" >> $SPARK_HOME/conf/slaves
  done
}

conf::set_env() {
  local memory="$1"
  local port=""
  rm -f $SPARK_HOME/conf/spark-env.sh

  echo "SPARK_WORKER_MEMORY=\"$memory\"" > $SPARK_HOME/conf/spark-env.sh
}

start::master() {
  local master_node="$1"

  ssh $SSH_OPTS $master_node "$SPARK_HOME/sbin/start-master.sh"
}

start::slaves() {
  local master_node="$1"

  ssh $SSH_OPTS $master_node "$SPARK_HOME/sbin/start-slaves.sh"
}

main() {
  local nodes=( $(expand::nodelist "$NODES") )
  local master_node="${nodes[0]}"
  local slave_nodes="${nodes[@]}"

  conf::set_master "$master_node"
  conf::set_slaves "$slave_nodes"
  conf::set_env "$JOB_MEM"
  start::master "$master_node"
  start::slaves "$master_node"

  echo "#-------------------------------------------------------------------------------"
  echo "# INFO"
  echo "#-------------------------------------------------------------------------------"
  echo "Master Node: $master_node"
  echo "Slave Node(s): $slave_nodes"
  echo "Job Memory: $JOB_MEM"

  echo "#-------------------------------------------------------------------------------"
  echo "# Stopping your spark cluster"
  echo "#-------------------------------------------------------------------------------"
  echo "ssh $SSH_OPTS $master_node \"$SPARK_HOME/sbin/stop-all.sh\""

  echo "#-------------------------------------------------------------------------------"
  echo "# Running an example (for testing)"
  echo "#-------------------------------------------------------------------------------"
  echo "ssh $SSH_OPTS $master_node"
  echo "MASTER=\"spark://${master_node}:7077\""
  echo "$SPARK_HOME/bin/run-example \"org.apache.spark.examples.SparkPi\" \"2\"\""
}

main
