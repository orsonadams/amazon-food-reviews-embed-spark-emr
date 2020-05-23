#!/bin/sh

# create cluster docs: https://docs.aws.amazon.com/cli/latest/reference/emr/create-cluster.html
## --applications is important; EMR nodes will not install Spark on the nodes if this is not set / or not set to Spark
#  --configurations allows setting up the spark-env; we use that to set the python version we'll run spark-submit with
#                   and to set the IPC format since Spark 2.4.5 uses the old IPC format and arrow > 0.15.0 supports
# 		    supports a new version see ( ./spark.conf.json ) for the configurations and for more details see
#		    this https://spark.apache.org/docs/2.4.5/sql-pyspark-pandas-with-arrow.html#compatibiliy-setting-for-pyarrow--0150-and-spark-23x-24x
aws emr create-cluster \
	--name "Reviews Cluster" \
	--ec2-attributes KeyName=<your-key-name> \
	--configurations file://spark.conf.json \
	--applications Name=Spark \
	--release-label emr-5.29.0 \
	--instance-type m4.xlarge --instance-count 3 \ # 1 node used as the chief and the other 2 as workers
	--use-default-roles \
	--enable-debugging \
	--log-uri s3://<logging-bucket>/aws-reviews/logs # you're going to need this
	--bootstrap-actions Path=s3://<bootstrap-bucket>/bootstrap-emr-nodes-conda.sh
