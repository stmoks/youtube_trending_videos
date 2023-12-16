# Youtube Trending Videos

## AWS Account

The first step is to create an AWS account. It is important to note the difference between the root user and the IAM user. Upon creation of the account, a root user will be created by default. This user has admin rights to all the resources. It is, therefore, the most susceptible to any attacks. For anyone using the resources of the account, IAM user accounts should be created and permissions should be managed by policies and roles.

It is also recommended that you enable multi-factor authentication. For the IAM root account, but ideally also for the IAM users.

## AWS Configuration

Once the account has been created, we need to make sure that we can play around with AWS resources programatically. For that we use the AWS CLI and SDK to get going. I used the pip installer to download the CLI. From there, we can run the config commands to get moving. We will need to use the access keys and secrets that we can find on the IAM resource.

## Uploading Data

We are using Youtube data taken from Kaggle. In this dataset, we have information about the top trending videos on Youtube. Once we have the dataset downloaded on our local machine, we can now upload it to a Simple Storage Service (S3) bucket. The advantage of this service, particularly in the context of Youtube data, is that it supports both structured and semi-structured data.

Since we have the AWS CLI set up, we can run shell commands to upload the data into the relevant bucket. Along the way, we are reorganising the data into folders that are more useful.

## Data Catalog

Next, we use AWS Glue to build a data catalog around our data. In this step, we are essentially creating metadata that will make it possible to run other resources. You will need to create a role so that AWS Glue can interact with S3. In this step, you will also assign Glue 2 sets of permissions that will allow you to perform all the typical actions necessary around metadata and schema creation.

We need to create a catalog database and table for the raw data. For the clean data, we can simply create the database in Glue and then use the Lambda function to create the table.

## Lambda Function

We need to create a Lambda function and grant it similar permissions to the ones we gave the AWS Glue crawler. The function forms part of the pipeline and will be triggered to transform the raw data into clean data - in our case converting JSON data to the parquet format.

In the function, we use the AWS Wrangler package to make it easy to use Panda-like functionality on our dataset. Within the Lambda function script, we create code to read in environment variables that will help us move our data from the raw layer to the clean layer.

Speaking of layers, the AWS Wrangler package did not work as per normal once we added it to the Lambda function code on AWS. To fix that issue, we added a layer that contained all the Pandas dependencies we need to run the subsequent commands. Once we are happy, we can test and deploy the lambda function.

When you have deployed the Lambda code, you can then test it. Here, you just need to provide the relevant test parameters such as the bucket names, file path, and the test event. If the Lambda function times out, then you need to go to the configuration and increase your timeout duration. Remember, AWS Lambda currently has a timeout limit of 15 minutes. If you receive this error message: aws lambda: Error: Runtime exited with error: signal: killed, then you might need to increase the memory.

And if you encounter any more errors, don't forget that the various roles need to have policies attached to them in order in order to interact with the various AWS resources.

## Tips

- Don't forget to change your region
- Add the data to the gitignore file
