variable "prefix" {
  type        = string
  description = <<-EOT
  Prefix for all objects created by terraform.

  Primary identifier to 'group' together resources created by
  this terraform module. Prevents clashes with other resources
  in the cloud project / account.

  Should not be changed after first terraform apply - doing so
  will recreate all resources.

  Should not end with a '-', that is automatically added.
  EOT
}

variable "project_id" {
  type        = string
  description = <<-EOT
  GCP Project ID to create resources in.

  Should be the id, rather than display name of the project.
  EOT
}

variable "notebook_nodes" {
  type        = map(map(string))
  description = "Notebook node pools to create"
  default     = {}
}

variable "dask_nodes" {
  type        = map(map(string))
  description = "Dask node pools to create. Defaults to notebook_nodes"
  default     = {}
}

variable "config_connector_enabled" {
  type        = bool
  default     = false
  description = <<-EOT
  Enable GKE Config Connector to manage GCP resources via kubernetes.

  GKE Config Connector (https://cloud.google.com/config-connector/docs/overview)
  allows creating GCP resources (like buckets, VMs, etc) via creating Kubernetes
  Custom Resources. We use this to create buckets on a per-hub level,
  and could use it for other purposes in the future.

  Enabling this increases base cost, as config connector related pods
  needs to run on the cluster.
  EOT
}

variable "cluster_sa_roles" {
  type = set(string)
  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/artifactregistry.reader"
  ]
  description = <<-EOT
  List of roles granted to the SA assumed by cluster nodes.

  The defaults grant just enough access for the components on the node
  to write metrics & logs to stackdriver, and pull images from artifact registry.

  https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster
  has more information.
  EOT
}

variable "cd_sa_roles" {
  type = set(string)
  default = [
    "roles/container.admin",
    "roles/artifactregistry.writer"
  ]
  description = <<-EOT
  List of roles granted to the SA used by our CI/CD pipeline.

  We want to automatically build / push images, and deploy to
  the kubernetes cluster from CI/CD (on GitHub actions, mostly).
  A JSON key for this will be generated (with
  `terraform output -raw ci_deployer_key`) and stored in the
  repo in encrypted form.

  The default provides *full* access to the entire kubernetes
  cluster! This is dangerous, but it is unclear how to tamp
  it down.
  EOT
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = <<-EOT
  GCP Region the cluster & resources will be placed in.

  For research clusters, this should be closest to where
  your source data is.

  This does not imply that the cluster will be a regional
  cluster.
  EOT

}

variable "zone" {
  type        = string
  default     = "us-central1-b"
  description = <<-EOT
  GCP Zone the cluster & nodes will be set up in.

  Even with a regional cluster, all the cluster nodes will
  be on a single zone. NFS and supporting VMs will need to
  be in this zone as well.
  EOT
}

variable "core_node_machine_type" {
  type        = string
  default     = "g1-small"
  description = <<-EOT
  Machine type to use for core nodes.

  Core nodes will always be on, and count as 'base cost'
  for a cluster. We should try to run with as few of them
  as possible.

  For single-tenant clusters, a single g1-small node seems
  enough - if network policy and config connector are not on.
  For others, please experiment to see what fits.
  EOT
}

variable "core_node_max_count" {
  type        = number
  default     = 5
  description = <<-EOT
  Maximum number of core nodes available.

  Core nodes can scale up to this many nodes if necessary.
  They are part of the 'base cost', should be kept to a minimum.
  This number should be small enough to prevent runaway scaling,
  but large enough to support ocassional spikes for whatever reason.

  Minimum node count is fixed at 1.
  EOT
}

variable "enable_network_policy" {
  type        = bool
  default     = true
  description = <<-EOT
  Enable kubernetes network policy enforcement.

  Our z2jh deploys NetworkPolicies by default - but they are
  not enforced unless enforcement is turned on here. This takes
  up some cluster resources, so we could turn it off in cases
  where we are trying to minimize base cost.

  https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy
  has more information.
  EOT
}

variable "user_buckets" {
  type        = set(any)
  default     = []
  description = "Buckets to create for the project, they will be prefixed with {var.prefix}-"
}
