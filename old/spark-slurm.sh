#!/bin/bash

#SBATCH -J spark-test
#SBATCH -t 0:10:00

module load spark/spark-1.4.1

. start_spark_cluster.sh


#### Start the spark example/job

export DATA_SCRATCH=`pwd`

rm -rf ${DATA_SCRATCH}/wordcounts

cat > sparkscript.py <<EOF
from pyspark import SparkContext

sc = SparkContext(appName="wordCount")
file = sc.textFile("${DATA_SCRATCH}/moby-dick.txt")
counts = file.flatMap(lambda line: line.split(" ")).map(lambda word: (word, 1)).reduceByKey(lambda a, b: a+b)
counts.saveAsTextFile("${DATA_SCRATCH}/wordcounts")
EOF

spark-submit --master ${sparkmaster} sparkscript.py

#### End the spark example/job


sleep 10

. stop_spark_cluster.sh 
