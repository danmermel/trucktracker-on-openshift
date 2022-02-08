resource "ibm_container_vpc_cluster" "truckTrackerCluster" {
    name              = "truck-tracker-cluster"
    vpc_id            = ibm_is_vpc.truckTrackerVpc.id
    kube_version      = "4.8_openshift"
    flavor            = "bx2.4x16"
    worker_count      = "1"
    #entitlement       = "cloud_pak"
    cos_instance_crn  = ibm_resource_instance.truckTrackerCos.id
    resource_group_id = ibm_resource_group.resource_group.id
    zones {
        subnet_id = ibm_is_subnet.truckTrackerSubnet1.id
        name      = "eu-gb-1"
      }
    zones {
        subnet_id = ibm_is_subnet.truckTrackerSubnet2.id
        name      = "eu-gb-2"
      }
    zones {
        subnet_id = ibm_is_subnet.truckTrackerSubnet3.id
        name      = "eu-gb-3"
      }
}