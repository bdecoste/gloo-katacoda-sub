kubectl -n default create secret generic realm-secret --from-file="gloo-realm.json"

helm repo add codecentric https://codecentric.github.io/helm-charts
helm upgrade --install keycloak codecentric/keycloak \
  --namespace default \
  --values - <<EOF
keycloak:
  extraVolumes: |
    - name: realm-secret
      secret:
        secretName: realm-secret
  extraVolumeMounts: |
    - name: realm-secret
      mountPath: "/realm/"
      readOnly: true

  extraArgs: -Dkeycloak.import=/realm/gloo-realm.json

  service:
    type: NodePort
EOF

wait_until_ready "Keycloak" "default" "2"

glooctl add route -n default --dest-namespace gloo-system \
    --name keycloak  \
    --path-prefix /auth \
    --dest-name default-keycloak-http-keycloak-0-80

PROXY_URL="$(glooctl proxy url)"

glooctl create secret --namespace gloo-system --name keycloak oauth --client-secret client-secret
