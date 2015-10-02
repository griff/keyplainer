# keyplainer

A small utility to check that EC2 machines on an account only uses whitelisted key pairs

```
cat config.yml | docker run -i -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY griff/keyplainer
``` 

## Sample config

```
---
allowed_keys:
  - 1c:77:16:0d:7e:24:27:95:32:ce:e1:33:d2:30:e2:0d
  - ac:b1:47:34:bd:49:b5:1c:f5:9c:ff:6d:d8:c6:84:e2 # test4

#regions:
#  - eu-west-1
#  - eu-central-1
```

## AWS Policy

To run the script only needs the folowing policy:

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "ec2:DescribeInstances",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "ec2:DescribeKeyPairs",
            "Resource": "*"
        }
    ]
}
```