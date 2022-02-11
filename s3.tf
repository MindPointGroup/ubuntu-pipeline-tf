# Done once at creation time, should be a secondary tf IaaC repo
# resource "aws_s3_bucket" "org500-infra-data-dump" {
#   bucket = "org500-infra-data-dump"
#   acl = "private"
# }

# # To upload all the config files in the folder org500-infra-data-dump

# resource "aws_s3_bucket_object" "org500-infra-data-dump" {
#   bucket = aws_s3_bucket.org500-infra-data-dump.id
#   for_each = fileset("var/tmp/", "*")
#   key = each.value
#   source = "org500-infra-data-dump/${each.value}"
#   etag = filemd5("org500-infra-data-dump/${each.value}")
# }