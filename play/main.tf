provider "google" {
  project = "runxc-test"
  region = "us-central1"
  zone = "us-central1-a"
}

module "init" {
  source = "../init"
  name = "dev1"
}

output "gcp-network" {
  value = module.init.gcp-network
}
