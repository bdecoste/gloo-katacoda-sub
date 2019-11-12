## Istio mTLS Integration

First, enable mTLS in the gateway by adding the istio-certs volume and volumeMount:

```
volumeMounts:
- mountPath: /etc/envoy
  name: envoy-config
- mountPath: /etc/certs/
  name: istio-certs
  readOnly: true
volumes:
- configMap:
  name: gateway-envoy-config
name: envoy-config
- name: istio-certs
  secret:
    defaultMode: 420
    optional: true
    secretName: istio.default
```

`kubectl -n gloo-system edit deploy/gateway-proxy-v2`{{execute}}

Verify that the proxy pod has been restarted after the gateway deployment change:
`kubectl -n gloo-system get pods | grep gateway-proxy-v2`{{execute}}

Second, enable mTLS in the upstream by adding the sslConfig:

```
spec:
  discoveryMetadata: {}
  upstreamSpec:
    sslConfig:
      sslFiles:
        tlsCert: /etc/certs/cert-chain.pem
        tlsKey: /etc/certs/key.pem
        rootCa: /etc/certs/root-cert.pem
    kube:
      selector:
        app: productpage
      serviceName: productpage
      serviceNamespace: default
      servicePort: 9080
```

`kubectl -n gloo-system edit upstream default-productpage-9080`{{execute}}

Next, add the route to the product page upstream:
`glooctl add route --name prodpage --namespace gloo-system --path-prefix / --dest-name default-productpage-9080 --dest-namespace gloo-system`{{execute}}

Verify that the virtual service and route have been created and are Accepted:
`glooctl get virtualservice`{{execute}}

Test that the productpage application is now accessible through the gateway over mTLS:
`curl -v $(glooctl proxy url)/productpage`{{execute}}
