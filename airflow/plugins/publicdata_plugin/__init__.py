from airflow.plugins_manager import AirflowPlugin
from publicdata_plugin.hooks.custom_postgres_hook import CustomPostgresHook
from publicdata_plugin.operators.download_file_operator import DownloadFileOperator
from publicdata_plugin.operators.pandas_to_postgres_operator import PandasToPostgresTransfer

# Views / Blueprints / MenuLinks are instantied objects
class PublicDataPlugin(AirflowPlugin):
	name 			= "publicdata_plugin"
	operators 		= [ DownloadFileOperator, PandasToPostgresTransfer ]
	sensors			= []
	hooks			= [ CustomPostgresHook ]
	executors		= []
	admin_views		= []
	flask_blueprints	= []
	menu_links		= []