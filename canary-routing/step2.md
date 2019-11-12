## Cleanup (Optional)

First, remove the virtual service:
`glooctl delete virtualservice default`{{execute}}

Second, remove the upstream:
`glooctl delete upstream default-petstore-8080`{{execute}}

Third, remove the petstore application:
`kubectl delete --filename https://raw.githubusercontent.com/sololabs/demos2/master/resources/petstore.yaml`{{execute}}

