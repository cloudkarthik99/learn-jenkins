terraform {
  backend "s3" {
    bucket  = "terraform-state-buckets-k8s-and-tools"
    key     = "github/jenkins-server.tfstate"
    region  = "us-east-1"
    profile = "karthik"
  }
}
