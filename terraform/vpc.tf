resource "ibm_is_vpc" "truckTrackerVpc" {
  name = "truck-tracker-vpc"
}

resource "ibm_is_vpc_routing_table" "truckTrackerRoutingTable" {
  name   = "truck-tracker-routing-table"
  vpc    = ibm_is_vpc.truckTrackerVpc.id
}


resource "ibm_is_subnet" "truckTrackerSubnet1" {
  name            = "truck-tracker-subnet1"
  vpc             = ibm_is_vpc.truckTrackerVpc.id
  zone            = "eu-gb-1"
  ipv4_cidr_block = "10.242.0.0/18"
  routing_table   = ibm_is_vpc_routing_table.truckTrackerRoutingTable.routing_table 
  public_gateway = ibm_is_public_gateway.truckTrackerGateway1.id
}

resource "ibm_is_subnet" "truckTrackerSubnet2" {
  name            = "truck-tracker-subnet2"
  vpc             = ibm_is_vpc.truckTrackerVpc.id
  zone            = "eu-gb-2"
  ipv4_cidr_block = "10.242.64.0/18"
  routing_table   = ibm_is_vpc_routing_table.truckTrackerRoutingTable.routing_table  
  public_gateway = ibm_is_public_gateway.truckTrackerGateway2.id

}

resource "ibm_is_subnet" "truckTrackerSubnet3" {
  name            = "truck-tracker-subnet3"
  vpc             = ibm_is_vpc.truckTrackerVpc.id
  zone            = "eu-gb-3"
  ipv4_cidr_block = "10.242.128.0/18"
  routing_table   = ibm_is_vpc_routing_table.truckTrackerRoutingTable.routing_table  
  public_gateway = ibm_is_public_gateway.truckTrackerGateway3.id
}

resource "ibm_is_public_gateway" "truckTrackerGateway1" {
  name = "truck-tracker-gateway-1"
  vpc  = ibm_is_vpc.truckTrackerVpc.id
  zone = "eu-gb-1"
}

resource "ibm_is_public_gateway" "truckTrackerGateway2" {
  name = "truck-tracker-gateway-2"
  vpc  = ibm_is_vpc.truckTrackerVpc.id
  zone = "eu-gb-2"
}

resource "ibm_is_public_gateway" "truckTrackerGateway3" {
  name = "truck-tracker-gateway-3"
  vpc  = ibm_is_vpc.truckTrackerVpc.id
  zone = "eu-gb-3"
}