#Private Subnet
resource "aws_subnet" "private_subnet" {
  count             = length(var.private_subnet_cidr)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidr[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(
    local.common_tags,
    {
      "Name"                                      = "Private_subnet_${data.aws_availability_zones.available.names[count.index]}"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
      "kubernetes.io/role/internal-elb"           = "1"
    },
  )
}

#Public Subnet used by bastion host
resource "aws_subnet" "public_subnet" {
  count             = length(var.public_subnet_cidr)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnet_cidr[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(
    local.common_tags,
    {
      "Name"                                      = "Public_subnet_${data.aws_availability_zones.available.names[count.index]}"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
      "kubernetes.io/role/elb"                    = "1"
    },
  )
}

#EKS Kubernetes Subnet
resource "aws_subnet" "master_subnet" {
  count             = length(var.master_subnet_cidr)
  vpc_id            = aws_vpc.this.id
  cidr_block        = element(var.master_subnet_cidr, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = merge(
    local.common_tags,
    {
      Name = "Master_${element(data.aws_availability_zones.available.names, count.index)}"
    },
  )
}

#Worker Nodes
resource "aws_subnet" "worker_subnet" {
  count             = length(var.worker_subnet_cidr)
  vpc_id            = aws_vpc.this.id
  cidr_block        = element(var.worker_subnet_cidr, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = merge(
    local.common_tags,
    {
      Name = "Worker_${element(data.aws_availability_zones.available.names, count.index)}"
    },
  )
}

#Public Route Table
resource "aws_route_table" "rt_public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "Public_route_table"
    },
  )
}

#Public Route Table Association
resource "aws_route_table_association" "master" {
  count          = length(var.master_subnet_cidr)
  subnet_id      = element(aws_subnet.master_subnet.*.id, count.index)
  route_table_id = aws_route_table.rt_public.id
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidr)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.rt_public.id
}

#VPC Elastic IP
resource "aws_eip" "eip" {
  vpc = true

  tags = merge(
    local.common_tags,
    {
      Name = "Elastic IP"
    },
  )
}

#NatGatways
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = element(aws_subnet.master_subnet.*.id, 0)

  tags = merge(
    local.common_tags,
    {
      Name = "Nat_gateway"
    },
  )
}

#Private Route Table
resource "aws_route_table" "rt_private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw.id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "Private_route_table"
    },
  )
}

#Private Route Table Association
resource "aws_route_table_association" "worker" {
  count          = length(var.worker_subnet_cidr)
  subnet_id      = element(aws_subnet.worker_subnet.*.id, count.index)
  route_table_id = aws_route_table.rt_private.id
}

resource "aws_route_table_association" "private_sub" {
  count          = length(var.private_subnet_cidr)
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = aws_route_table.rt_private.id
}