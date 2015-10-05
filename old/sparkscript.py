from pyspark import SparkContext

sc = SparkContext(appName="wordCount")
file = sc.textFile("/home/shuang/test/spark2/moby-dick.txt")
counts = file.flatMap(lambda line: line.split(" ")).map(lambda word: (word, 1)).reduceByKey(lambda a, b: a+b)
counts.saveAsTextFile("/home/shuang/test/spark2/wordcounts")
