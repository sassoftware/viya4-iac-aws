FROM hashicorp/terraform:0.13.3

RUN apk --update --no-cache add python3 py3-pip \
    && pip3 install --upgrade pip \
    && pip3 install "awscli==1.18.169" \
    && rm -rf /var/cache/apk/*

WORKDIR /viya4-iac-aws

COPY . .

RUN terraform init /viya4-iac-aws