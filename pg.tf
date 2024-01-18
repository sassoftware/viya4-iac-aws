# SAS placement group
resource "aws_placement_group" "sas" {
  name     = "${var.prefix}-pg"
  strategy = "cluster"
}
