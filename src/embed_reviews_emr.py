import sys
from collections import namedtuple
from itertools  import tee

import numpy as np
import pandas as pd

import pyspark.sql.functions as F
from pyspark.mllib.linalg import VectorUDT, DenseVector
from pyspark.sql.types import *
from pyspark import SQLContext
from pyspark import SparkConf, SparkContext

import tensorflow_hub as hub

# NOTE: for now we're loading the embeddings in each partiion :(
# have to figure out how to broadcast the USE model.
MODEL_URL = 'https://tfhub.dev/google/universal-sentence-encoder/4'

PARTITIONS = 100 # split the data into `PARTITIONS` partitions
WRITE_PARTITIONS = 16 # write 16 parquet files
MAX_REVIEW_LENGTH = 100 # truncate reviews to 100 words
    
Embed = namedtuple('Embed', ['id', 'value'])
schema = StructType([StructField('id', IntegerType()),
                    StructField('value', VectorUDT())])


def simple_embed(batch):
    texts, ids = tee(batch)
    texts = [str(b.Text) for b in texts]
    ids =   [b.Id   for b in ids]
    em = hub.KerasLayer(MODEL_URL)
    m = np.asarray(em(texts))
    return [Embed(id=idx, value=emb) for (idx, emb) in zip(ids, m)]
    
if __name__ == '__main__':

    data, out = sys.argv[1:]
    conf = SparkConf().setAppName('ResNETBroadCast')
    conf.set('spark.sql.execution.arrow.enable', 'true')
    # smaller batches for nodes with small memory
    conf.set('spark.sql.execution.arrow.maxRecordsPerBatch', '1024')
    # allow overwrite s3 files
    conf.set('spark.hadoop.orc.overwrite.output.file', 'true') #
    
    sc = SparkContext.getOrCreate(conf)
    spark = SQLContext(sc)
    data = spark.read.csv(data, inferSchema=True, header=True)
    # filter documents longer than MAX_REVIEW_LENGTH words
    data = data.withColumn('review_length',
                           F.size(F.split(F.col('Text'), ' ')))
    
    data = data.where(F.col('review_length') <= MAX_REVIEW_LENGTH)
    # repartition and embed 
    res = data.repartition(PARTITIONS)\
            .rdd.mapPartitions(simple_embed)\
            .map(lambda x: (x.id, DenseVector(x.value)))
    
    frame = spark.createDataFrame(res, schema=schema)
    # out is an s3 bucket
    frame.repartition(WRITE_PARTITIONS)\
        .write.mode('overwrite')\
        .format('parquet')\
        .save(out)
