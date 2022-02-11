sudo mkdir /var/tmp/data1
sudo mv ip*.json /var/tmp/data1
aws s3 cp /var/tmp/data s3://org500-infra-data-dump --recursive