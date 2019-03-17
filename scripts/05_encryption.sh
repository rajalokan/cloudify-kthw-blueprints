#! /bin/bash -e

ctx logger info "Generating & copying cert authority"
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

for instance in ctrl0 ctrl1 ctrl2; do
  scp -i ~/.ssh/cloud.pem encryption-config.yaml centos@${instance}.${DOMAIN}:
done
