## ssh key

1. Generate your ssh key
```bash
ssh-keygen -t rsa -b 2048 -f ~/.ssh/stevejc-ec2-test-key-pair.pem -q -P ''
chmod 400 ~/.ssh/stevejc-ec2-test-key-pair.pem
ssh-keygen -y -f ~/.ssh/stevejc-ec2-test-key-pair.pem > ~/.ssh/stevejc-ec2-test-key-pair.pub
```

2. Log in EC2

After instance is booting up.

```bash
cd ~/.ssh
sudo chmod 400 stevejc-ec2-test-key-pair.pem
ssh -i "stevejc-ec2-test-key-pair.pem" ubuntu@54.66.145.13
```