## Gateway TLS

Deploy the Pet Store app to kubernetes
`kubectl apply -f petstore.yaml`{{execute}}

Verify the petstore pod is Running and the petstore service has been created:
`kubectl -n default get all`{{execute}}

The discovery services should have already created an Upstream for the petstore service. Let’s verify this:
`glooctl get upstreams`{{execute}}

Let’s take a closer look at the upstream that Gloo’s Discovery service created:
`glooctl get upstream default-petstore-8080 --output yaml`{{execute}}

Let’s now use glooctl to create a basic route for this upstream.
`glooctl add route \
    --path-prefix /api \
    --dest-name default-petstore-8080`{{execute}}

Let’s test the route using curl to the hjttp port:
`curl $(glooctl proxy url --port https)/api/pets`{{execute}}

### Section 1

Now generate the TLS keys and certificate:
`openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
   -keyout tls.key -out tls.crt -subj "/CN=petstore.example.com"`{{execute}}

And the corresponding secret:
`kubectl create secret tls gateway-tls --key tls.key \
   --cert tls.crt --namespace gloo-system`{{execute}}

Now configure the default virtual service to use the TLS secret:
`glooctl edit virtualservice --name default --namespace gloo-system \
   --ssl-secret-name gateway-tls --ssl-secret-namespace gloo-system`{{execute}}

Take a look at the updated virtual service and note the new sslConfig:
`glooctl get virtualservice default -o yaml`{{execute}}

Retest the route using curl to the http port. This hangs as the http port is now closed.
`curl $(glooctl proxy url --port http)/api/pets`{{execute}}

Try the https port:
`curl $(glooctl proxy url --port https)/api/pets`{{execute}}

### Section 2

Create a second route and virtual service with a new set of keys, certificate, and secret:
`openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
   -keyout tls.key -out tls.crt -subj "/CN=animalstore.example.com"`{{execute}}

`kubectl create secret tls animal-certs --key tls.key \
    --cert tls.crt --namespace gloo-system`{{execute}}

`glooctl add route --name animal\
   --path-exact /animals \
   --dest-name default-petstore-8080 \
   --prefix-rewrite /api/pets`{{execute}}

And update the new virtual service with the new credentials:
`glooctl edit virtualservice --name animal --namespace gloo-system \
   --ssl-secret-name animal-certs --ssl-secret-namespace gloo-system \
   --ssl-sni-domains animalstore.example.com`{{execute}}

Now test the new route:
`curl -k -H "Host: animalstore.example.com" $(glooctl proxy url --port https)/animals`{{execute}}
