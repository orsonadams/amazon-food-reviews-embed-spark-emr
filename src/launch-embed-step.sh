#!/bin/sh

## Don forget to update the buckets:
#  <input-bucket>
#  <output-bucket>


# Args to `spark-submit` most are self explanatory.
# 	--cluster deploy in cluster mode: a YARN driver will managen the cluster
# 	--master yarn
#       --conf spark.yarn.submit.waitAppCompletion, block until task complete. setting this to false
#		will allow the process to return after registering the step. Allowing for other steps to be
# 		registered
#	 --num-executors effectively the number of worker nodes
# ActionOnFailure is an EMR paramater that tells cluster what to do if a step fails
# This will result in call to spark-submit that look like this:

# 	spark-submit --deploy-mode cluster \
#		     --master yarn \ 
#		     --conf spark.yar.submit.waitAppCompletion true \
# 		     --num-executors 2 \
# 		     --num-executor-cores 5 \
# 		     --executor-memory 10g \
#		     s3://<input-bucket>/job/embed_reviews_emr.py s3://<input-bucket>/input/Reviews.csv s3://<output-bu#cket>/output/embed-parquet
# 	       

aws emr add-steps \
	--cluster-id $1 \
	--steps Type=spark,Name="ReviewEmbed",Args=[--deploy-mode,cluster,--master,yarn,--conf,spark.yarn.submit.waitAppCompletion=true,--num-executors,2,--executor-cores,5,--executor-memory,10g,s3://<input-bucket>/job/embed_reviews_emr.py,s3://<input-bucket>/input/Reviews.csv,s3://<output-bucket>/embed-parqut],ActionOnFailure=CONTINUE
