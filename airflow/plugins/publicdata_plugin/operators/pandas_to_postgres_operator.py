import json
from airflow.models import BaseOperator

from airflow.hooks.postgres_hook import PostgresHook
from airflow.hooks.S3_hook import S3Hook
from airflow.utils.decorators import apply_defaults

class PandasToPostgresTransfer(BaseOperator):
	"""
	Moves data from Pandas Dataframe to Postgres.
	Source file must be in S3 bucket
	
	:param s3_conn_id: s3 connection
	:type df: str

	:param postgres_conn_id: target PostgreSQL connection
	:type postgres_conn_id: str

	:param source_file: file with data to be loaded
	:type source_file: str

	:param table_name: target table name
	:type table_name: str
	"""
	
	@apply_defaults
	def __init__(self, s3_conn_id='s3_default', postgres_conn_id='postgres_default', source_file=None, table_name=None, *args, **kwargs):
		super(PandasToPostgresTransfer, self).__init__(*args, **kwargs)
		self.s3_conn_id 			= s3_conn_id
		self.postgres_conn_id		= postgres_conn_id
		self.source_file 			= source_file
		self.table_name 			= table_name

	def execute(self, context):
		execution_date = context['execution_date']
		temporary_table = "temp_{}_{}".format(self.table_name,execution_date)

		postgres 	= PostgresHook(postgres_conn_id=self.postgres_conn_id).get_conn()
		s3 			= S3Hook(aws_conn_id=self.s3_conn_id)