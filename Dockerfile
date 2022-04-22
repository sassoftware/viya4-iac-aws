ARG TERRAFORM_VERSION=1.0.0
ARG AWS_CLI_VERSION=2.1.29
FROM hashicorp/terraform:$TERRAFORM_VERSION as terraform

FROM amazon/aws-cli:$AWS_CLI_VERSION
ARG KUBECTL_VERSION=1.21.7

WORKDIR /viya4-iac-aws

COPY --from=terraform /bin/terraform /bin/terraform
COPY . .

RUN yum -y install git openssh jq which \
  && curl -sLO https://storage.googleapis.com/kubernetes-release/release/v$KUBECTL_VERSION/bin/linux/amd64/kubectl \
  && chmod 755 ./kubectl /viya4-iac-aws/docker-entrypoint.sh \
  && mv ./kubectl /usr/local/bin/kubectl \
  && chmod g=u -R /etc/passwd /etc/group /viya4-iac-aws \
  && git config --global --add safe.directory /viya4-iac-aws \
  && terraform init
  
ENV TF_VAR_iac_tooling=docker
ENTRYPOINT ["/viya4-iac-aws/docker-entrypoint.sh"]
VOLUME ["/workspace"]
