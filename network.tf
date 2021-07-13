module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "3.3.0"
  project_id   = module.enabled_google_apis.project_id
  network_name = "${var.cluster_name}-${var.cluster_env}-network"
  routing_mode = "REGIONAL"

  subnets = [
    {
      subnet_name           = "${var.cluster_name}-${var.cluster_env}-subnet"
      subnet_ip             = var.subnet_ip
      subnet_region         = var.region
      subnet_private_access = true
      description           = "This subnet is managed by Terraform"
    }
  ]
  secondary_ranges = {
    "${var.cluster_name}-${var.cluster_env}-subnet" = [
      {
        range_name    = "ip-range-pods"
        ip_cidr_range = var.ip_range_pods
      },
      {
        range_name    = "ip-range-svc"
        ip_cidr_range = var.ip_range_svc
      },
    ]
  }
}

module "cloud-nat" {
  source        = "terraform-google-modules/cloud-nat/google"
  project_id    = module.enabled_google_apis.project_id
  region        = var.region
  router        = "${var.cluster_name}-${var.cluster_env}-router"
  network       = module.vpc.network_self_link
  create_router = true
}

resource "google_compute_global_address" "google-managed-service-range" {
  project = module.enabled_google_apis.project_id
  name = "google-managed-services-${module.vpc.network_name}"
  purpose = "VPC_PEERING"
  prefix_length = 16
  address_type = "INTERNAL"
  network = module.vpc.network_self_link
}

resource "google_service_networking_connection" "private-service-access" {
  network = module.vpc.network_self_link
  reserved_peering_ranges = [google_compute_global_address.google-managed-service-range.name]
  service = "servicenetworking.googleapis.com"
  depends_on = [google_compute_global_address.google-managed-service-range]
}