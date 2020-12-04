ARG TERRAFORM_VERSION=0.13.4
ARG AWS_CLI_VERSION=2.1.7

FROM hashicorp/terraform:$TERRAFORM_VERSION as terraform
FROM amazon/aws-cli:$AWS_CLI_VERSION
ARG KUBECTL_VERSION=1.18.8

RUN curl -sLO https://storage.googleapis.com/kubernetes-release/release/v$KUBECTL_VERSION/bin/linux/amd64/kubectl \
  && chmod 755 ./kubectl \
  && mv ./kubectl /usr/local/bin/kubectl
COPY --from=terraform /bin/terraform /bin/terraform

WORKDIR /viya4-iac-aws
 
COPY . .

RUN yum -y install git openssh \
  && terraform init /viya4-iac-aws

ENV TF_VAR_iac_tooling=docker
ENTRYPOINT ["/bin/terraform"]
