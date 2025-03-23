import sys

from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext

## @params: [JOB_NAME]
args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Load raw data from Glue Data Catalog
raw_data = glueContext.create_dynamic_frame.from_catalog(
    database="youtube_trending_db",
    table_name="your_glue_table_name"
)

# Drop null values
cleaned_data = DropNullFields.apply(frame=raw_data)

# Convert to Parquet format and save to S3
output_path = "s3://<BUCKET>/processed_data/"
glueContext.write_dynamic_frame.from_options(
    frame=cleaned_data,
    connection_type="s3",
    connection_options={"path": output_path, "partitionKeys": ["country", "date"]},
    format="parquet"
)

job.commit()
