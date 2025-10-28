resource "null_resource" "create_namespace" {
  provisioner "local-exec" {
    command = "kubectl create namespace blue-green --dry-run=client -o yaml | kubectl apply -f -"
  }
}

output "service_url" {
  value = "Access app at: http://localhost:30080"
}
