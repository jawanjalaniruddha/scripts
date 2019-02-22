#!/bin/bash -x

# This script will help to setup AWS Cloudwatch custom metric for Disk, Memory after every 5 mintues
# for Ubuntu instace.
# 
# Create a custom Cloudwatch user & attach following policy to it. This user will have required access to # Cloudwatch	

<<COMMENT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData",
                "ec2:DescribeTags",
                "logs:PutLogEvents",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:ListMetrics",
                "logs:DescribeLogStreams",
                "logs:DescribeLogGroups",
                "logs:CreateLogStream",
                "logs:CreateLogGroup"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameter",
                "ssm:PutParameter"
            ],
            "Resource": "arn:aws:ssm:*:*:parameter/AmazonCloudWatch-*"
        }
    ]
}
COMMENT

# Link: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/mon-scripts.html
#Command to verify: /opt/aws-scripts-mon/mon-put-instance-data.pl --mem-util --verify --verbose

sudo apt-get update 
sudo apt-get -y install libwww-perl libdatetime-perl

cd /opt

curl https://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.2.zip -O

unzip -u /opt/CloudWatchMonitoringScripts-1.2.2.zip && \
rm -v /opt/CloudWatchMonitoringScripts-1.2.2.zip && \
cd /opt/aws-scripts-mon

#https://stackoverflow.com/questions/8488253/how-to-force-cp-to-overwrite-without-confirmation
yes | cp -f awscreds.template awscreds.conf


echo 'AWSAccessKeyId=XXXXXXXXXXXXXXXXXXXXX
AWSSecretKey=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' | tee /opt/aws-scripts-mon/awscreds.template


cat <<EOF > /etc/cron.d/aws-custom-cloudwatch
*/5 * * * *	root	/opt/aws-scripts-mon/mon-put-instance-data.pl --mem-used-incl-cache-buff --mem-util --mem-used --mem-avail --disk-path=/dev/xvda1 --disk-space-util --disk-space-used --disk-space-avail --swap-util --swap-used --aws-credential-file=/opt/aws-scripts-mon/awscreds.conf --from-cron
EOF

perl /opt/aws-scripts-mon/mon-put-instance-data.pl --mem-used-incl-cache-buff --mem-util --mem-used --mem-avail --disk-path=/dev/xvda1 --disk-space-util --disk-space-used --disk-space-avail --swap-util --swap-used --aws-credential-file=/opt/aws-scripts-mon/awscreds.conf  --verbose >> /opt/aws-scripts-mon/cwinit.log
