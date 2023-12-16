import awswrangler as wr
import pandas as pd
import urllib.parse
import os

os_input_s3_clean_layer = os.environ['s3_clean_layer']
os_input_glue_catalog_db_name = os.environ['glue_catalog_db_name']
os_input_glue_catalog_table_name = os.environ['glue_catalog_table_name']
os_input_write_data_operation = os.environ['write_data_operation']


def lambda_handler(event,context):
    # get the object from the event and show it's content type
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'],encoding='utf-8')
    try:

        # create a dataframe from content
        df_raw = wr.s3.read_json(f's3://{bucket}/{key}')

        # extract required columns
        df_step_1 = pd.json_normalize(df_raw['items'])

        #write to s3
        wr_response = wr.s3.to_parquet(
            df = df_step_1,
            path = os_input_s3_clean_layer,
            dataset=True,
            database=os_input_glue_catalog_db_name,
            table=os_input_glue_catalog_table_name,
            mode=os_input_write_data_operation,
        )
        return wr_response
    except Exception as e:
        print(e)
        print('Error getting object {key} from bucket {bucket}. Make sure that these exist and that the bucket is in the same region as the Lambda function')
        raise e

# for single file output
#  output_s3_uri = f"s3://{os_input_s3_cleansed_layer}/{os_input_glue_catalog_table_name}/output.parquet"
#     wr.s3.to_parquet(df, output_s3_uri, index=False)

