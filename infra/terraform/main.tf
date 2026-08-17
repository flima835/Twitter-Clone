provider "google" {
  project = "twitter-clone-sre"
  region  = "us-central1"
}

resource "google_container_cluster" "primary" {
  name     = "twitter-clone-cluster"
  location = "us-central1-a"

  # desabilita proteção de exclusão
  deletion_protection = false

  # Criando um cluster leve para testes (preemptible nodes para economizar)
  initial_node_count = 1
  node_config {
  # preemptible  = true
    machine_type = "e2-medium"
  }
}