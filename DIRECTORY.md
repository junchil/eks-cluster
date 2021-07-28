## Directory Structure


```
.
├── app/
|
├── doc/
|
├── infra/
|   ├── charts/
|   |   └── rea-web/
|   |
|   |── eks/
|   |   ├── bastion-host/
|   |   ├── cluster/
|   |   ├── vpc/
|   |   ├── main.tf
|   |   ├── output.tf
|   |   ├── provider.tf
|   |   ├── variables.tf
|   |   └── version.tf
|   |── terraform-state/
|   └── Makefile
|
|── scripts/
|
├── ssh-key/
|   
├── testbox/
|
├── Makefile
|   
└── .travis.yml  
```

An overview of what each of these does:

| File | Description |
| -------- | ----------- |
| `app/` | Web applicaton |
| `doc/` | README pictures |
| `infra/` | Terraform and Helm code |
| `charts/` | Helm code |
| `rea-web/` | Web applications helm charts |
| `eks/` | Terraform code |
| `bastion-host` | Terraform code for setup bastion host |
| `cluster` | Terraform code for setup eks cluster |
| `vpc` | Terraform code for setup vpc |
| `terraform-state` | Terraform code for setup terraform remote state |
| `Makefile` | Deployment code for terraform and helm |
| `scripts` | scripts folder |
| `ssh-key` | Public key for bastion host ssh key |
| `testbox` | Simple linux box for testing web service in cluster |
| `Makefile` | Copy ssh key and setup AWS credentials |
| `.travis.yml` | Travis configuration file |