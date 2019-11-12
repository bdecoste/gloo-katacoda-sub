## Gateway mTLS

Deploy a TLS application to kubernetes
`kubectl apply -f tls-server.yaml`{{execute}}

Wait until the TLS server pod is ready:
`kubectl -n default get pods`{{execute}}

Wait until the discovery service has discovered the corresponding upstream and the upstream is Accepted:
`glooctl get upstream default-example-tls-server-8080`{{execute}}

Now add a route and virtual service for the application:
`glooctl add route \
    --path-exact /hello \
    --dest-name default-example-tls-server-8080`{{execute}}

Wait until the route and virtual service are Accepted:
`glooctl get virtualservice default`{{execute}}

Try to access the application. Because the application is expecting a TLS connection, this will fail:
`curl $(glooctl proxy url)/hello`{{execute}}

Create a secret based on the keys and certificate corresponding to the TLS application:
`kubectl create secret tls upstream-tls --key key.pem \
   --cert cert.pem --namespace default`{{execute}}

Now update the upstream to use the secret:
`glooctl edit upstream \
    --name default-example-tls-server-8080 \
    --namespace gloo-system \
    --ssl-secret-name upstream-tls \
    --ssl-secret-namespace default`{{execute}}

Take a look at the upstream and note the new sslConfig:
`kubectl get upstream -n gloo-system default-example-tls-server-8080 -o yaml`{{execute}}

Retest the request:
`curl $(glooctl proxy url)/hello`{{execute}}
