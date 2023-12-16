rem Upload data to an S3 bucket
rem cp is for copy, then the dot lets you know that it will copy all the files from the current directory, then you can create new folders within the path, and then use additional options
rem The following includes json but excludes everything else
rem recursive means that the command will copy all files and subdirectories
rem exclude ignores everything so that we can have the include json right after
aws s3 cp data/. s3://dataeng-on-youtube-raw-euwest1-dev/youtube/raw_reference_data/ --recursive --exclude "*" --include "*.json"

aws s3 cp data/CAvideos.csv s3://dataeng-on-youtube-raw-euwest1-dev/youtube/raw_statistics/region=ca/
aws s3 cp data/DEvideos.csv s3://dataeng-on-youtube-raw-euwest1-dev/youtube/raw_statistics/region=de/
aws s3 cp data/FRvideos.csv s3://dataeng-on-youtube-raw-euwest1-dev/youtube/raw_statistics/region=fr/
aws s3 cp data/GBvideos.csv s3://dataeng-on-youtube-raw-euwest1-dev/youtube/raw_statistics/region=gb/
aws s3 cp data/INvideos.csv s3://dataeng-on-youtube-raw-euwest1-dev/youtube/raw_statistics/region=in/
aws s3 cp data/JPvideos.csv s3://dataeng-on-youtube-raw-euwest1-dev/youtube/raw_statistics/region=jp/
aws s3 cp data/KRvideos.csv s3://dataeng-on-youtube-raw-euwest1-dev/youtube/raw_statistics/region=kr/
aws s3 cp data/MXvideos.csv s3://dataeng-on-youtube-raw-euwest1-dev/youtube/raw_statistics/region=mx/
aws s3 cp data/RUvideos.csv s3://dataeng-on-youtube-raw-euwest1-dev/youtube/raw_statistics/region=ru/
aws s3 cp data/USvideos.csv s3://dataeng-on-youtube-raw-euwest1-dev/youtube/raw_statistics/region=us/



