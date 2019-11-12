## Pet Store

Deploy the Pet Store app to kubernetes
`kubectl apply -f petstore.yaml`{{execute}}

Verify the petstore pod is Running and the petstore service has been created:
`kubectl -n default get all`{{execute}}

The discovery services should have already created an Upstream for the petstore service. Let’s verify this:
`glooctl get upstreams default-petstore-8080`{{execute}}

Let’s take a closer look at the upstream that Gloo’s Discovery service created:
`glooctl get upstream default-petstore-8080 --output yaml`{{execute}}

Let’s now use glooctl to create a basic route for this upstream.
`glooctl add route \
    --name petstore \
    --path-exact /all-pets \
    --dest-name default-petstore-8080 \
    --prefix-rewrite /api/pets`{{execute}}

Let’s verify that a virtual service was created with that route.
`glooctl get virtualservice petstore`{{execute}}

Let’s test the route /all-pets using curl:
`curl -H "user-agent:scammer" $(glooctl proxy url)/all-pets`{{execute}}
