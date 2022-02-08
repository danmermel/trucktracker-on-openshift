resource "ibm_resource_instance" "truckTrackerCos" {
  name     = "truck-tracker-cos"
  service  = "cloud-object-storage"
  plan     = "standard"
  location = "global"
}