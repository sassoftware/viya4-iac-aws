ARG TERRAFORM_VERSION=1.10.5
ARG AWS_CLI_VERSION=2.24.16
FROM hashicorp/terraform:$TERRAFORM_VERSION AS terraform

FROM almalinux:minimal AS amin
WORKDIR /app
USER root
ARG KUBECTL_VERSION=1.31.7
ARG KUBECTL_CHECKSUM=80a3c83f00241cd402bc8688464e5e3eedd52a461ee41d882f19cf04ad6d0379
RUN /usr/bin/bash -eux \
  && curl -fSLO https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
  && chmod 755 ./kubectl \
  && sha256sum --check --strict <(echo ${KUBECTL_CHECKSUM}  kubectl)

FROM amazon/aws-cli:$AWS_CLI_VERSION

WORKDIR /viya4-iac-aws

COPY --from=amin /app/kubectl /usr/local/bin/kubectl
COPY --from=terraform /bin/terraform /bin/terraform
COPY . .

RUN yum -y install git openssh jq which \
  && yum -y update openssl-libs glib2 vim-minimal vim-data curl \
  && yum clean all && rm -rf /var/cache/yum \
  && chmod 755 /viya4-iac-aws/docker-entrypoint.sh \
  && git config --system --add safe.directory /viya4-iac-aws \
  && terraform init \
  && chmod g=u -R /etc/passwd /etc/group /viya4-iac-aws

ENV TF_VAR_iac_tooling=docker
ENTRYPOINT ["/viya4-iac-aws/docker-entrypoint.sh"]
VOLUME ["/workspace"]
