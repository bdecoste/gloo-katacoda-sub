## Web Application Framework (WAF)

First, enable WAF in the gateway by adding the httpGateway configuration to the gateway:

```
apiVersion: gateway.solo.io.v2/v2
kind: Gateway
metadata:
  name: gateway-proxy-v2
  namespace: gloo-system
spec:
  bindAddress: '::'
  bindPort: 8080
  httpGateway:
    plugins:
      extensions:
        configs:
          waf:
            customInterventionMessage: ModSecurity intervention! Custom message details
              here..
            ruleSets:
            - ruleStr:
                SecRuleEngine On
                SecRule REQUEST_HEADERS:User-Agent "scammer" "deny,status:403,id:107,phase:1,msg:'blocked scammer'"
  proxyNames:
  - gateway-proxy-v2
  useProxyProto: false
  ```

`kubectl -n gloo-system edit gateway gateway-proxy-v2`{{execute}}

Let’s test the route /all-pets using curl:
`curl -H "user-agent:scammer" $(glooctl proxy url)/all-pets`{{execute}}

Remove the WAF config from the gateway and restore the httpGateway to:
```
httpGateway: {}
```

`kubectl -n gloo-system edit gateway gateway-proxy-v2`{{execute}}

Second, enable WAF in the virtual service by adding the virtualHostPlugins configuration to the gateway:

```
spec:
  virtualHost:
    domains:
    - '*'
    virtualHostPlugins:
      extensions:
        configs:
          waf:
            settings:
              customInterventionMessage: 'ModSecurity intervention! Custom message details here..'
              ruleSets:
                - ruleStr:
                    SecRuleEngine On
                    SecRule REQUEST_HEADERS:User-Agent "scammer" "deny,status:403,id:107,phase:1,msg:'blocked scammer'"
```

`kubectl -n gloo-system edit virtualservices.gateway.solo.io petstore`{{execute}}

Let’s test the route /all-pets using curl:
`curl -H "user-agent:scammer" $(glooctl proxy url)/all-pets`{{execute}}
