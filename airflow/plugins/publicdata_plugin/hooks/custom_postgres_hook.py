from airflow.utils.log.logging_mixin import LoggingMixin
from airflow.hooks.postgres_hook import PostgresHook

class CustomPostgresHook(PostgresHook, LoggingMixin):
	"""
	Hook extension to load data from CSV choosing the delimiter

	
	"""
    def __init__(self, *args, **kwargs):
        super(CustomPostgresHook, self).__init__(*args, **kwargs)
    
    def bulk_load_csv(self, table, tmp_file, delimiter):
        """
        Loads a csv file into a database table
        """
        self.copy_expert("COPY {table} FROM STDIN WITH (FORMAT CSV, HEADER TRUE, DELIMITER ;) ".format(table=table), tmp_file)