#!/bin/bash
# Start Spark Cluster by shuang

export SPARK=spark/spark-1.4.1

module load $SPARK

nodes=($( srun hostname | sort ))

nnodes=${#nodes[@]}
last=$(( $nnodes - 1 ))

PID=`pwd`/spark-${SLURM_JOB_ID}.pid
>$PID

export SSH_OPTS="-o StrictHostKeyChecking=no"

export SPARK_LOCAL_DIRS=/local/scratch/$USER
export SCRATCH=/scratch/$USER
if [ ! -d $SCRATCH ]; then
  mkdir $SCRATCH
fi

MEM=$(scontrol show jobid $SLURM_JOB_ID | grep Memory | awk '{print $2}' | awk -F"=" '{print $2}')

# start the master of the spark cluster
ssh ${SSH_OPTS} ${nodes[0]} "module load $SPARK; nohup spark-class org.apache.spark.deploy.master.Master --ip ${nodes[0]} &> ${SCRATCH}/nohup-Master-${nodes[0]}-${SLURM_JOB_ID}-0.out &\echo -n Master: 0 ${nodes[0]} \$! >> $PID" &

sleep 5

sparkmaster=`egrep "Starting Spark master" ${SCRATCH}/nohup-Master-${nodes[0]}-${SLURM_JOB_ID}-0.out | awk '{print $NF}'`

WEBUI=`egrep "MasterWebUI" ${SCRATCH}/nohup-Master-${nodes[0]}-${SLURM_JOB_ID}-0.out | awk '{print $NF}'`

echo "  WebUI: $WEBUI" >> $PID


# start the workers of the spark cluster
for i in $( seq 0 $last )
do
#   echo Worker: ${nodes[$i]} >> $PID
    ssh ${SSH_OPTS} ${nodes[$i]} "module load $SPARK; nohup spark-class org.apache.spark.deploy.worker.Worker ${sparkmaster} --ip ${nodes[$i]} -c 1 -m $MEM &> ${SCRATCH}/nohup-Worker-${nodes[$i]}-${SLURM_JOB_ID}-$i.out &\echo Worker: $i ${nodes[$i]} \$! >> $PID" &
done

sleep 10
