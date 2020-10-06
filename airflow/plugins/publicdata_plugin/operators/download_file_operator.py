import requests
import datetime
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
import logging
from airflow.models import Variable
import io
import pandas as pd


class DownloadFileOperator(BaseOperator):
	"""
	Download file from URL and save it to S3 bucket.
	
	:param s3_conn_id: s3 connection
	:type df: str

	:param url: file's url to be download
	:type url: str

	:param bucket: bucket to save the file
	:type bucket: str

	:param key: key of the file to be saved into s3 bucket
	:type key: str
	"""
	
	@apply_defaults
	def __init__(self, s3_conn_id='s3_default', url=None, bucket=None, key=None, *args, **kwargs):
        super(PostgresToElasticsearchTransfer, self).__init__(*args, **kwargs)
        self.s3_conn_id = s3_conn_id
        self.url = url
        self.bucket = bucket
        self.key = key
        self.log = logging.getLogger("airflow.task")

	def execute(self, context):
        self.log.info("Downloading file: {}".format(self.url))
        try:
            buffer = io.StringIO()
            df = pd.read_csv(url, encoding="utf-8", sep=";", header=0)
            df.to_csv(buffer, encoding="utf-8", sep=";", index=False)

            if buffer:
                s3 = S3Hook(aws_conn_id='klivo_aws_s3')
                s3.load_bytes(bytes_data=io.BytesIO(buffer.getvalue().encode('utf-8')).read(),
                                key=self.key,
                                bucket_name=self.bucket,
                                replace=True,
                                encrypt=True
                                )
                context['ti'].xcom_push(key='file_key', value=self.key)
            else:
                self.log.error("Failed to convert DF to utf-8.")
                raise Exception
        except Exception as e:
            self.log.error("Error while getting file. Message: {}".format(e))
            raise Exception
        
        self.log.info("Download finished!)