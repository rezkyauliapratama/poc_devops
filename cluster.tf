# google_client_config and kubernetes provider must be explicitly specified like the following.
data "google_client_config" "default" {}

provider "kubernetes" {
  load_config_file       = false
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version                    = "14.3.0"
  project_id                 = module.enabled_google_apis.project_id
  name                       = "${var.cluster_name}-${var.cluster_env}-gke"
  regional                   = false
  region                     = var.region
  zones                      = ["asia-southeast2-a"]
  network                    = module.vpc.network_name
  network_project_id         = ""


  kubernetes_version         = "latest"

  release_channel            = "STABLE"

  master_authorized_networks = [
    {
      cidr_block = "${module.bastion.ip_address}/32"
      display_name = "Bastion Host"
    }]

  subnetwork = module.vpc.subnets_names[0]
  ip_range_pods = module.vpc.subnets_secondary_ranges[0].*.range_name[0]
  ip_range_services = module.vpc.subnets_secondary_ranges[0].*.range_name[1]


  add_cluster_firewall_rules = false
  firewall_priority = 1000
  firewall_inbound_ports = [
    "8443",
    "9443",
    "15017"]

  horizontal_pod_autoscaling = true
  http_load_balancing = true

  network_policy = true

  maintenance_start_time = "05:00"
  initial_node_count = 0

  remove_default_node_pool = true
  cluster_autoscaling = {
    enabled = true
    autoscaling_profile = "OPTIMIZE_UTILIZATION"
    max_cpu_cores = 24
    min_cpu_cores = 0
    max_memory_gb = 96
    min_memory_gb = 0
  }

  node_pools = [
    {
      name = "default-node-pool"
      min_count = 1
      max_count = 6
      auto_upgrade = true
      node_metadata = "GKE_METADATA_SERVER"

      machine_type = "e2-medium"
      local_ssd_count = 0
      disk_size_gb = 100
      disk_type = "pd-standard"
      image_type = "COS"
      auto_repair = true
      preemptible = true
      autoscaling = true
    }
  ]

  node_pools_labels = {
    all = {}
    default-node-pool = {
        default-node-pool = true
    }
  }
  node_pools_metadata = {
    all = {}
    default-node-pool = {
      shutdown-script = file("${path.module}/data/shutdown-script.sh")
    }
  }
  
  node_pools_taints = {
    all = []
    default-node-pool = []
  }

  node_pools_tags = {
    all = []
    default-node-pool = [
      "default-node-pool",
    ]
  }

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/cloud-platform"]
    default-node-pool = []
  }


  stub_domains = {}
  upstream_nameservers = []

  logging_service = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  create_service_account = true
  service_account = ""
  grant_registry_access = true

  basic_auth_username = ""
  basic_auth_password = ""

  issue_client_certificate = false

  cluster_resource_labels = {}

  enable_private_endpoint = true
  deploy_using_private_endpoint = true

  enable_private_nodes = true

  master_ipv4_cidr_block = var.ip_range_master

  default_max_pods_per_node = 110

  database_encryption = [
    {
      state = "DECRYPTED"
      key_name = ""
    }
  ]

  enable_binary_authorization = true

  resource_usage_export_dataset_id = ""

  enable_vertical_pod_autoscaling = false

  identity_namespace = "${module.enabled_google_apis.project_id}.svc.id.goog"

  enable_shielded_nodes = true

  skip_provisioners = false


}
