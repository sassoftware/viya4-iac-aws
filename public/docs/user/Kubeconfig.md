# Kubernetes Configuration File Generation

## Overview

Generating a kube config file for the AWS Infrastructure as Code (IaC) repository supports two options.

The options are:

- Provider Based
- Kubernetes Service Account and Cluster Role Binding

### Provider Based - AWS Cloud Provider

This option creates a kube config file that utilizes the `aws` CLI executable from Amazon. This method generates an `access_token` with an expiration time that is refreshed each time you use the kube config file to access your cluster.

Portability is more limited with this option given the file is tied to the authentication method used to create the file.

### Kubernetes Service Account and Cluster Role Binding

This option creates a static kube config file that includes creation of the following:

- Service Account
- Cluster Role Binding

Once created, the `Service Account` is used to provide the `ca cert` and `token` embedded in the kube config file.

This kube config file option is quite portable as the `ca cert` and `token` for the cluster are static. Anyone who has this file can access the cluster.

## Usage

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| create_static_kubeconfig | Allows the user to create a provider- or service account-based kubeconfig file | bool | true | A value of `false` defaults to using the cloud provider's mechanism for generating the kubeconfig file. A value of `true` creates a static kubeconfig that uses a service account and cluster role binding to provide credentials. |
