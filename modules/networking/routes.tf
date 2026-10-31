# Public Route Table (to Internet Gateway)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  
  tags = { Name = "${var.environment}-public-rt" }
}

resource "aws_route_table_association" "public" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private App Route Tables (to NAT Gateway)
resource "aws_route_table" "private_app" {
  count  = length(var.azs)
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    # If single_nat is true, all app subnets route to the 0th NAT. Otherwise, they route to their AZ's NAT.
    nat_gateway_id = var.single_nat ? aws_nat_gateway.nat[0].id : aws_nat_gateway.nat[count.index].id
  }
  
  tags = { Name = "${var.environment}-private-app-rt-${var.azs[count.index]}" }
}

resource "aws_route_table_association" "private_app" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app[count.index].id
}

# Private Data Route Table (Isolated - no route to the internet)
resource "aws_route_table" "private_data" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.environment}-private-data-rt" }
}

resource "aws_route_table_association" "private_data" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.private_data[count.index].id
  route_table_id = aws_route_table.private_data.id
}