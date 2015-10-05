#!/bin/bash
# Stop Spark Cluster by shuang

if [ ! "x$SLURM_JOB_ID" == "x" ]; then
        PID=`pwd`/spark-${SLURM_JOB_ID}.pid
        cat $PID | while read line
        do
                echo $line | awk '{print"ssh -o StrictHostKeyChecking=no "$3" kill "$4}' | sh 2>/dev/null
        done
	rm $PID
        exit 0
fi

if [ $# -lt 1 ]; then
        echo ""
        echo "USAGE: `basename $0`  spark-jobid#.pid"
        echo ""
        exit 1
fi

cat $1 | while read line
do
        echo $line | awk '{print"ssh -o StrictHostKeyChecking=no "$3" kill "$4}' | sh 2>/dev/null
done
