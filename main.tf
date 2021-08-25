terraform {
  backend "remote" {
    organization = "mkaesz-dev"

    workspaces {
      name = "generate-mock-test"
    }
  }
}


resource "null_resource" "hello_world" {
  provisioner "local-exec" {
    command = "env"
  }
}

