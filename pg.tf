# SAS placement group
resource "aws_placement_group" "sas" {
  name     = "sas-pg"
  strategy = "cluster"
}
