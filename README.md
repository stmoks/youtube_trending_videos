# Youtube Trending Videos

# Kaggle Data

The data we use for this project is downloaded from Kaggle, an open-source dataset repository. The trending Youtube data consists of two parts - regional reference data saves as JSON and regional video statistics saved as CSVs.

## AWS Account

The first step is to create an AWS account. It is important to note the difference between the root user and the IAM user. Upon creation of the account, a root user will be created by default. This user has admin rights to all the resources. It is, therefore, the most susceptible to any attacks. For anyone using the resources of the account, IAM user accounts should be created and permissions should be managed by policies and roles.

It is also recommended that you enable multi-factor authentication. For the IAM root account, but ideally also for the IAM users.

## AWS Configuration

Once the account has been created, we need to make sure that we can play around with AWS resources programatically. For that we use the AWS CLI and SDK to get going. I used the pip installer to download the CLI. From there, we can run the config commands to get moving. We will need to use the access keys and secrets that we can find on the IAM resource.

## Uploading Data

We are using Youtube data taken from Kaggle. In this dataset, we have information about the top trending videos on Youtube. Once we have the dataset downloaded on our local machine, we can now upload it to a Simple Storage Service (S3) bucket. The advantage of this service, particularly in the context of Youtube data, is that it supports both structured and semi-structured data.

Since we have the AWS CLI set up, we can run shell commands to upload the data into the relevant bucket. Along the way, we are reorganising the data into folders that are more useful.

## Data Catalog - Reference Data

Next, we use AWS Glue to build a data catalog around our data. In this step, we are essentially creating metadata that will make it possible to run other resources. You will need to create a role so that AWS Glue can interact with S3. In this step, you will also assign Glue 2 sets of permissions that will allow you to perform all the typical actions necessary around metadata and schema creation.

We need to create a catalog database and table for the raw data. For the clean data, we can simply create the database in Glue and then use the Lambda function to create the table.

## Lambda Function

We need to create a Lambda function and grant it similar permissions to the ones we gave the AWS Glue crawler. The function forms part of the pipeline and will be triggered to transform the raw data into clean data - in our case converting JSON data to the parquet format.

The JSON data we have has some issues so we use the Lambda function to transform the reference data.

In the function, we use the AWS Wrangler package to make it easy to use Panda-like functionality on our dataset. Within the Lambda function script, we create code to read in environment variables that will help us move our data from the raw layer to the clean layer.

Speaking of layers, the AWS Wrangler package did not work as per normal once we added it to the Lambda function code on AWS. To fix that issue, we added a layer that contained all the Pandas dependencies we need to run the subsequent commands. Once we are happy, we can test and deploy the lambda function.

When you have deployed the Lambda code, you can then test it by using one of the test templates - in our case we use the s3-put event. Here, you just need to provide the relevant test parameters such as the bucket names, file path, and the test event. If the Lambda function times out, then you need to go to the configuration and increase your timeout duration. Remember, AWS Lambda currently has a timeout limit of 15 minutes. If you receive this error message: aws lambda: Error: Runtime exited with error: signal: killed, then you might need to increase the memory.

And if you encounter any more errors, don't forget that the various roles need to have policies attached to them in order in order to interact with the various AWS resources.

## Data Catalog - Statistics Data

Now that we are processing and loading the reference data accurately, we need to move on to the statistics data. The first thing we do is create another crawler that will establish schemas for the data coming from the CSVs. The database that we are loading to is still the raw one because we are yet to perform transformations. We are still only concerned with loading the data into the various schemas in S3. Once it is set up, we can run the crawler.

We can move back over to Athena to start playing around with our data. When we open up the side panel to preview our data, the raw_statistics table appears. Very importantly, this is now a partitioned table by region. We achieve this by using the convention of writing the folders according to the partition convention of "partition_name = partition_key". We now effectively have one unioned table when we run queries, but on the backend, we can significantly improve the performance of our queries when filtering by the region.

## Schema Changes

When trying to join our 2 sets of data (raw statistics data and clean reference data), we come across a small issue. The join key is the id and category id but the data types are incompatible. This, then, requires us to cast one of the data types to match the other. When the column is going to be used in different ways, then the use of a string can be flexible for later conversion to other data types. But, in this case, we know that we only be using these ids for joins. So in the side panel on AWS Glue, we can navigate to the relevant table and change the data type of the column of interest there.

We are not done yet. The change in the data catalog does not affect the parquet data that we are pulling in. Because the parquet data is still treating the column as a string, as it has it's own metadata that establishes data types, we need to effectively reingest the data for the change to take proper effect.

### Steps

1. Keep the data type change in the data catalog
2. Delete our clean parquet data in S3 (this is where the id column whose data type we are changing is stored)
3. Confirm APPEND command in Lambda so that data is being added to the updated and existing schema
4. Run Test event in Lambda
5. Copy our data from our raw layer into the clean layer
6. Add the S3 Trigger to Lambda

## ETL Job using PySpark - Base Script

To transform the statistics data, we will be using an ETL job rather than a Lambda function as we did with the reference data. This is because in a world where the statistics data is genuinely large, then a Lambda function will not always be able to perform the job. It has a 15 minute limitation and it lacks some of the visual features that are useful when setting up and reviewing ETL pipelines. We want to get a good idea of what is happening when we run the ETL job so we will set the Job Bookmark to "Enabled". We also want to be able to see our job metrics from CloudWatch.

The Visual ETL makes use of Directed Acylcic Graphs (DAGs) so the setup is fairly intuitive. For our "Change Schema" step, one of the things we are doing is converting columns from a long data type to a bigint - bigint can dynamically allocate space as needed. Something else we need to do is make sure that the data is stored in the same partitions as the raw data. For this, we make use of the Dynamic Frame class in AWS. This class is comparable to a pandas dataframe that we use in Python.

The default PySpark job, after using the GUI, is created to write the dataset into a single file but because we want to partition the data (in order to match with the source), we have to add our own logic to the script. Once we start making changes to the script, we are no longer able to use the GUI and everything moving forward needs to be added programatically. Once we've added the logic, we run the job to see if is working.

If the job gives you a not found error, then you want to check a few things:

1. Figure out what the real problem is, different pages might have different error messages which don't reflect the full extent of the problem. One error message I was getting was simply saying that my job doesn't exist yet the real problem was that I had typo in my script. The typo was reflected on a different page and this was obviously the reason for the supposedly non-existent job.
2. The job name is typed correctly, be aware of the case-sensitivity
3. Make sure that the role assigned to the resource has the necessary permissions
4. As always, check that you are working in the correct region
5. Make sure you save changes you make to the job before running it

In an intermediate step, we convert the dynamic frame to a Spark DataFrame so that we can use some Spark operations and functionalities. In particular, we reduce the number of partitions in the source data to 1 using the coalesce method.

## ETL Job using PySpark - Encoding

Since we are working with the data from around the world, some of it is not in the standard English character set. So, ideally, we want to ensure that the encoding settings are correct before we transform and ingest the data. Initially, we only extract data that from Canada, Great Britain, and the United States because this will allow us to avoid the encoding issues. We do this by adding a pushdown predicate option to the extraction logic. A pushdown predicate allows us to filter on partitions without having to list and read all the files in your dataset Once done, we test the pipeline and once we are happy that it is working, we started adding logic to deal with the encoding.

## Lambda Triggers

Next, we go back to our Lambda function that we created to bring in the raw reference data. We are adding a trigger that will invoke the Lambda function whenever JSON data is uploaded to the specified s3 location. Since our Lambda function was created to transform and load data into the clean bucket, this is precisely what it will do once it is triggered. This could be someone deleting files, adding files, copying files, and a number of other things which can be configured more precisely. In the trigger wizard, we add the key to the prefix textbox. And then in the suffix, we add the JSON file extension - .json.

## Analytics Bucket and Database

Now that we have good quality data in the clean layer, we are moving further by creating a reporting layer. We go back to AWS Glue and create another job that will be responsible for transforming the data even further. Although we used a Lambda job and Glue ETL job to transform the 2 sets of data between the raw and clean layer, this time we are using one ETL job to transform the data to the reporting layer. This is because we want to join the data to create one unified dataset upstream to reduce query costs and improve accuracy downstream. Using the Visual ETL tool, we create a join node along with a target node that outputs the data in an analytics bucket. While uploading the data to s3, we also want to create a table in our data catalog. For the database table, we are adding two partition keys - the region and the category id. We also can't forget to assign the relevant role to the resource - in our case, the same glue role we have been using throughout.

## QuickSight

The final step in the process is to visualise our data. We will be using AWS QuickSight and the first thing we need to do is create a _standard_ QuickSight account if we don't yet have one. Once that is created, we need to give QuickSight access to the data that we will use to build our dashboards. We navigate to the 'Manage Quicksight' option and go to the 'Security and permissions' page. We can now create a data source using the Athena data that is in our analytics layer. Finally, we create a QuickSight Analysis and we can start producing all the answers to our burning questions.

## Tips

- Don't forget to change your region
- Add the dataset to the gitignore file

## Questions

1. How do bookmarks work in PySpark?
2. How do we control how many files, post-tranformation or processing, various uses create? Focus on Lambda and PySpark/Glue ETL.
3. How do we (effectively) move data from S3 to a database?
4. How serious is this warning when creating a Lambda function: "using the same S3 bucket for both input and output is not recommended and that this configuration can cause recursive invocations, increased Lambda usage, and increased costs."?
5. Once we

## Tools

Glue ETL, S3, Glue Data Catalog, Python, PySpark,

## todo

- add data quality rules/transformations on the data as it goes into clean/reporting
- fix the encoding issue i.e. find a way to remove push down predicate
- create ETL diagram
