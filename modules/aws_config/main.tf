# ###########################  CONFIG ENABLEMENT  ###############################
resource "aws_config_conformance_pack" "NIST_conformance_pack" {
  name            = var.conformance_pack_name
  template_s3_uri = "s3://awsconfigconforms-awsng-conformance-pack-${var.hub_environment}/Operational-Best-Practices-for-NIST-800-53-rev-5.yaml"
}

resource "aws_config_conformance_pack" "NIST_SASCustom_conformance_pack" {
  name            = var.custom_conformance_pack_name
  template_s3_uri = "s3://awsconfigconforms-awsng-conformance-pack-${var.hub_environment}/SAS-Custom-Conformance-Pack.yaml"
}






