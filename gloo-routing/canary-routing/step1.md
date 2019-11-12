## Canary Routing

Deploy v1 of the the petstore application:
`kubectl apply -f petstore-v1.yaml`{{execute}}

Verify the petstore-v1 pod is Running and the petstore-v1 service has been created:
`kubectl -n default get all`{{execute}}

The discovery services should have already created an Upstream for the petstore-v1 service. Let’s verify this:
`glooctl get upstreams default-petstore-v1-8080`{{execute}}

Let’s now use glooctl to create a basic route for this upstream.
`glooctl add route \
    --name petstore \
    --path-exact /petstore \
    --dest-name default-petstore-v1-8080 \
    --prefix-rewrite /api/pets`{{execute}}

Let’s verify that a virtualservice was created with that route and that the virtualservice is Accepted:
`glooctl get virtualservice petstore`{{execute}}

Let’s test the route /petstore using curl:
`curl $(glooctl proxy url)/petstore`{{execute}}

Deploy v2 of the the petstore application:
`kubectl apply -f petstore-v2.yaml`{{execute}}

Verify the petstore-v2 pod is Running and the petstore-v2 service has been created:
`kubectl -n default get all`{{execute}}

The discovery services should have already created an Upstream for the petstore-v2 service. Let’s verify this:
`glooctl get upstreams default-petstore-v2-8080`{{execute}}

Let’s now use glooctl to create a basic route for this v2 upstream, but this time we will specify a header value for the route:
`glooctl add route \
   --name petstore \
   --path-prefix /petstore \
   --dest-name default-petstore-v2-8080 \
   --prefix-rewrite /api/pets \
   --header x-petstore-v2=true`{{execute}}

Let’s test the route /petstore using curl for both v1 and v2:
`curl $(glooctl proxy url)/petstore`{{execute}}

`curl -H "x-petstore-v2:true" $(glooctl proxy url)/petstore`{{execute}}

Now apply 50/50 weighting to the original route:
`kubectl apply -f weighted_petstore.yaml`{{execute}}

Lets see what changed:
`glooctl get virtualservice petstore -o yaml`{{execute}}

Lets test the route /petstore with no header and we should see a 50/50 response distribution between v1 and v2:
`for i in {1..10}; do curl $(glooctl proxy url)/petstore; done`{{execute}}
