resource "local_file" "deployment" {
  content  = data.local_file.deployment.content
  filename = "${var.destination_path}/${var.file_name}.yaml"
}