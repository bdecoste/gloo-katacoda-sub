## Cleanup (Optional)

First, remove the route:
`glooctl remove route --name weather`{{execute}}

Second, remove the virtual service:
`glooctl delete virtualservice weather`{{execute}}

Third, remove the upstream:
`glooctl delete upstream weather`{{execute}}

