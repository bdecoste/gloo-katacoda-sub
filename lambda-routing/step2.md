## Cleanup (Optional)

First, remove the route:
`glooctl remove route --name lambda`{{execute}}

Second, remove the virtual service:
`glooctl delete virtualservice lambda`{{execute}}

Third, remove the upstream:
`glooctl delete upstream lambda`{{execute}}

Fourth, remove the secret:
`kubectl -n gloo-system delete secret lambda`{{execute}}

