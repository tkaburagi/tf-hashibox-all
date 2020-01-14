{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "ec2:*",
            "Resource": "*",
            "Effect": "Allow",
            "Condition": {
                "StringEquals": {
                    "ec2:Region": "${region}"
                }
            }
        },
        {
          "Effect": "Allow",
          "Action": "iam:*",
          "Resource": "*"
        },
        {
          "Effect": "Allow",
          "Action": "s3:*",
          "Resource": "*"
        }
    ]
}
