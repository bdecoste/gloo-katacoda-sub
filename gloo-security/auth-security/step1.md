## Auth

Disable external authentication for the Keycloak application by adding routePlugins:

```
spec:
  virtualHost:
    domains:
    - '*'
    routes:
    - matcher:
        prefix: /auth
      routeAction:
        single:
          upstream:
            name: default-keycloak-http-keycloak-0-80
            namespace: gloo-system
      routePlugins:
        extensions:
          configs:
            extauth:
              disable: true
```

`kubectl -n default edit virtualservice keycloak`{{execute}}

Set the Gateway IP address:
`export PROXY_URL=$(glooctl proxy url)`{{execute}}

Create the Keycloak-authenticated virtual service for the petstore application:
`glooctl create virtualservice --namespace gloo-system --name oauth --enable-oidc-auth \
    --oidc-auth-client-secret-name keycloak \
    --oidc-auth-client-secret-namespace gloo-system \
    --oidc-auth-issuer-url ${PROXY_URL}/auth/realms/gloo/ \
    --oidc-auth-client-id gloo \
    --oidc-auth-app-url ${PROXY_URL} \
    --oidc-auth-callback-path /callback`{{execute}}

Create the Route for the petstore applciation in the Keycloak-authenticated virtual service:
`glooctl add route \
    --name oauth  \
    --path-prefix /api \
    --dest-name default-petstore-8080`{{execute}}

Test that the Keycloak login page is hit when the petstore application is accessed through the Gateway:
`curl -s -L $(glooctl proxy url)/api/pets | grep kc-form-login`{{execute}}
