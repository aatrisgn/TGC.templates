data "local_file" "deployment" {
  filename = "${var.source_path}/${var.file_name}.yaml"
}