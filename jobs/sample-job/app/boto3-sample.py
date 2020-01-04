import boto3
s3 = boto3.resource('s3')
bucket_iterator = s3.buckets.all()
for bucket in bucket_iterator:
    print(bucket)