ARG TERRAFORM_VERSION=1.9.6
ARG AWS_CLI_VERSION=2.17.58
FROM hashicorp/terraform:$TERRAFORM_VERSION AS terraform

FROM amazon/aws-cli:$AWS_CLI_VERSION
ARG KUBECTL_VERSION=1.29.8

WORKDIR /viya4-iac-aws

COPY --from=terraform /bin/terraform /bin/terraform
COPY . .

RUN yum -y install git openssh jq which \
  && yum -y update openssl-libs glib2 vim-minimal vim-data curl \
  && yum clean all && rm -rf /var/cache/yum \
  && curl -sLO https://storage.googleapis.com/kubernetes-release/release/v$KUBECTL_VERSION/bin/linux/amd64/kubectl \
  && chmod 755 ./kubectl /viya4-iac-aws/docker-entrypoint.sh \
  && mv ./kubectl /usr/local/bin/kubectl \
  && git config --system --add safe.directory /viya4-iac-aws \
  && terraform init \
  && chmod g=u -R /etc/passwd /etc/group /viya4-iac-aws

ENV TF_VAR_iac_tooling=docker
ENTRYPOINT ["/viya4-iac-aws/docker-entrypoint.sh"]
VOLUME ["/workspace"]
