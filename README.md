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

## Sample output

```
Unused key pairs:
    US West (Oregon) Main 82:a0:80:f1:3e:42:99:96:e4:24:d8:fc:0d:84:f9:06:c1:11:02:d3
    EU (Ireland) test1 e6:b9:6c:a6:5a:96:bb:3a:79:fb:7f:44:0e:19:7e:06
Machines with no key pair:
    EU (Frankfurt) build-aget i-05d9a8af
    EU (Frankfurt) test-site i-d25a0178
Machines with an unallowed key pair:
    EU (Ireland) junk-mailer i-540e5ffe svp 5d:84:f6:1c:2d:f4:c2:59:42:4f:53:e1:a5:2a:43:8c
    EU (Frankfurt) griff-test i-c2135b0c griff 7c:4a:57:8d:4d:71:7d:bf:ba:57:31:1a:28:69:96:0e
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

## License

```
The MIT License (MIT)

Copyright (c) 2015 Brian Olsen

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```