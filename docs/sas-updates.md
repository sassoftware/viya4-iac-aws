New in SAS Viya platform 2021.2.6: the connect workload class is no longer required. For more information, see [Connect Workload Class Changes](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=v_026&docsetId=itopswn&docsetTarget=n0jh2fbifqgoksn1uou9p2zgbzdy.htm#p15778dvqwzjtgn1e95nq9v0y1wv).

To deploy the SAS Viya platform 2021.2.6 and later, use the most recent version of SAS Viya 4 Infrastructure as Code. The default settings do not create a connect node pool. If your current software order has a requirement for the connect node pool, you can use the connect node pool example file in `examples/sample-input-connect.tfvars`.

If you are updating the SAS Viya platform to version 2021.2.6, take some additional steps to remove the connect nodes.

1.	Perform the update by following the steps in the [SAS Viya platform documentation](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=v_043&docsetId=k8sag&docsetTarget=p043aa4ghwwom6n1beyfifdgkve7.htm).
2.	When the update to 2021.2.6 has completed successfully, edit the sample-input-*.tfvars to scale down the connect node pool. Change `min_nodes` and `max_nodes` to 0:
```
  connect = {
    "vm_type" = "m5.8xlarge"
    "os_disk_type" = "gp2"
    "os_disk_size" = 200
    "os_disk_iops" = 0
    "min_nodes" = 0
    "max_nodes" = 0
    "node_taints" = ["workload.sas.com/class=connect:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class"        = "connect"
      "launcher.sas.com/prepullImage" = "sas-programming-environment"
       }
    "custom_data" = ""
    "metadata_http_endpoint"               = "enabled"
    "metadata_http_tokens"                 = "required"
    "metadata_http_put_response_hop_limit" = 1
  },
```
3. Run `terraform apply` using your edited tfvars file.
