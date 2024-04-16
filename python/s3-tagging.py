import boto3
from botocore.config import Config

config = Config(
   retries = {
      'max_attempts': 10,
      'mode': 'standard'
   }
)

boto3.setup_default_session(profile_name='xxxxxx')

cf_untagged = []
noncf_untagged = []

def list_s3_buckets():
    """
    Lists all S3 buckets in the AWS account.
    """
    s3 = boto3.client('s3')
    response = s3.list_buckets()
    buckets = [bucket['Name'] for bucket in response['Buckets']]
    return buckets

def is_cf_bucket(bucket_name):
    client = boto3.client('s3', config=config)
    try:
        tags = client.get_bucket_tagging(Bucket=bucket_name)['TagSet']
        for tag in tags:
            if tag['Key'] == 'aws:cloudformation:stack-name':
                return True
    except:
        pass
    return False    

def check_component_tag(bucket_name):
    """
    Checks if the specified S3 bucket has the "Component" tag.
    """
    s3 = boto3.client('s3')
    response = s3.get_bucket_tagging(Bucket=bucket_name)
    tags = response.get('TagSet', [])
    for tag in tags:
        if tag['Key'] == 'Component':
            return True
    return False

def main():
    buckets = list_s3_buckets()
    for bucket in buckets:
        if is_cf_bucket(bucket):
            if check_component_tag(bucket):
                print(f"The bucket '{bucket}' was created using CloudFormation and has XXXXX tag.")
            else:
                print(f"CHECK: The bucket '{bucket}' was created using CloudFormation but does not have XXXXX tag.")
                cf_untagged.append(bucket)
        else:
            print(f"CHECK: The bucket '{bucket}' was not created using CloudFormation & does not have XXXXX tag")
            noncf_untagged.append(bucket)

    print(f"NON CF UNTAGGED: {noncf_untagged}")
    print(f"CF UNTAGGED: {cf_untagged}")

if __name__ == "__main__":
    main()
