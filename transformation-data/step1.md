## Data Transformation

Create an Upstream for the external application postman-echo.com:
`glooctl -n gloo-system create upstream static --name echo --static-hosts postman-echo.com:80`{{execute}}

Create a route and corresponding virtual service for the postman-echo application:
`glooctl add route  \
    --name echo  \
    --path-prefix / \
    --dest-name echo`{{execute}}

Make sure the virtual service and route are Accepted:
`glooctl get upstream echo`{{execute}}

### Section 1
In the first section, we will demonstrate transforming the http response code based posted data.

Test the postman-echo upstream. You should see a 200 response with the contents of data-transformed.json:
`cat data-transformed.json`{{execute}}

`curl -s -o /dev/null -w "%{http_code}" -H "Content-Type: application/json" $(glooctl proxy url)/post -d @data-transformed.json`{{execute}}

`curl -H "Content-Type: application/json" $(glooctl proxy url)/post -d @data-transformed.json | jq`{{execute}}

To change the response code, edit the virtual service by adding the virtualHostPlugins:
```
spec:
  virtualHost:
    domains:
    - '*'
    routes:
    - matcher:
        prefix: /
      routeAction:
        single:
          upstream:
            name: postman-echo
            namespace: gloo-system
    virtualHostPlugins:
      transformations:
        responseTransformation:
          transformationTemplate:
            headers:
              # We set the response status via the :status pseudo-header based on the response code
              ":status":
                text: '{% if default(data.error.message, "") != "" %}400{% else %}{{ header(":status") }}{% endif %}'
```

`kubectl -n gloo-system edit virtualservice echo`{{execute}}

Test the transformed response code:
`curl -s -o /dev/null -w "%{http_code}" -H "Content-Type: application/json" $(glooctl proxy url)/post -d @data-transformed.json`{{execute}}

Test a different post that does not trigger the response code transformation:

`cat data-not-transformed.json`{{execute}}

`curl -s -o /dev/null -w "%{http_code}" -H "Content-Type: application/json" $(glooctl proxy url)/post -d @data-not-transformed.json`{{execute}}

### Section 2
In the second section, we will demonstrate how to extract query parameters:

Test the baseline response from an http query. Note there are no foobar headers:
`curl -s "$(glooctl proxy url)/get?foo=foo-value&bar=bar-value" | jq`{{execute}}

Add the requestTransformation to the echo virtual service:

```
    virtualHostPlugins:
      transformations:
        requestTransformation:
          transformationTemplate:
            extractors:
              # This extracts the 'foo' query param to an extractor named 'foo'
              foo:
                # The :path pseudo-header contains the URI
                header: ':path'
                # Use a nested capturing group to extract the query param
                regex: '(.*foo=([^&]*).*)'
                subgroup: 2
              # This extracts the 'bar' query param to an extractor named 'bar'
              bar:
                # The :path pseudo-header contains the URI
                header: ':path'
                # Use a nested capturing group to extract the query param
                regex: '(.*bar=([^&]*).*)'
                subgroup: 2
            # Add two new headers with the values of the 'foo' and 'bar' extractions
            headers:
              foo:
                text: '{{ foo }}'
              bar:
                text: '{{ bar }}'
```

`kubectl -n gloo-system edit virtualservice echo`{{execute}}

Now test the configuration by issuing a query. Note that there are now foobar headers:
`curl -s "$(glooctl proxy url)/get?foo=foo-value&bar=bar-value" | jq`{{execute}}

### Section 3
In the third section, we will demonstrate how to conditionally update the request path.

Test the baseline response: Note that the url is a GET.
`curl -s -H "boo: far" $(glooctl proxy url)/get | jq`{{execute}}

Add the new headers to the requestTransformation:
```
      transformations:
        requestTransformation:
          transformationTemplate:
            headers:
              # By updating the :path pseudo-header, we update the request URI
              ":path":
                text: '{% if header("boo") == "far" %}/post{% else %}{{ header(":path") }}{% endif %}'
              # By updating the :method pseudo-header, we update the request HTTP method
              ":method":
                text: '{% if header("boo") == "far" %}POST{% else %}{{ header(":method") }}{% endif %}'
```

`kubectl -n gloo-system edit virtualservice echo`{{execute}}


Test the new transform. Note that the url is now a POST.
`curl -s -H "boo: far" $(glooctl proxy url)/get | jq`{{execute}}

Now test the transform without the header. Note that the transform is not triggered.
`curl -s $(glooctl proxy url)/get | jq`{{execute}}

### Section 4
In the fourth section, we will demonstrate how to extract headers and add them to the JSON request body.

Test the baseline using the following data. Note that the only data payload is "foo: bar".

`cat data-payload.json`{{execute}}

`curl -H "Content-Type: application/json" -H "root: root-val" -H "nested: nested-val" $(glooctl proxy url)/post -d @data-payload.json | jq`{{execute}}

To merge the headers into the body add the following extractors and merge_extractors_to_body tag to the requestTransformation:

```
          transformation_template:
            # Merge the specified extractors to the request body
            merge_extractors_to_body: {}
            extractors:
              # The name of this attribute determines where the value will be nested in the body (using dots)
              root:
                # Name of the header to extract
                header: 'root'
                # Regex to apply to it, this is needed
                regex: '.*'
              # The name of this attribute determines where the value will be nested in the body (using dots)
              payload.nested:
                # Name of the header to extract
                header: 'nested'
                # Regex to apply to it, this is needed
                regex: '.*'
```

`kubectl -n gloo-system edit virtualservice echo`{{execute}}

Now test updated transform. Note that the header has been added to the body.

`curl -H "Content-Type: application/json" -H "root: root-val" -H "nested: nested-val" $(glooctl proxy url)/post -d @data-payload.json | jq`{{execute}}

### Section 5
In the fifth section, we will demonstrate how to add custom attributes to the access logs.

First, enable access logging by adding the accessLoggingService plugin to the Gateway configuration:

```
spec:
  bindAddress: '::'
  bindPort: 8080
  httpGateway: {}
  plugins:
    accessLoggingService:
      accessLog:
      - fileSink:
          jsonFormat:
            # HTTP method name
            httpMethod: '%REQ(:METHOD)%'
            # Protocol. Currently either HTTP/1.1 or HTTP/2.
            protocol: '%PROTOCOL%'
            # HTTP response code. Note that a response code of ‘0’ means that the server never sent the
            # beginning of a response. This generally means that the (downstream) client disconnected.
            responseCode: '%RESPONSE_CODE%'
            # Total duration in milliseconds of the request from the start time to the last byte out
            clientDuration: '%DURATION%'
            # Total duration in milliseconds of the request from the start time to the first byte read from the upstream host
            targetDuration: '%RESPONSE_DURATION%'
            # Value of the "x-envoy-original-path" header (falls back to "path" header if not present)
            path: '%REQ(X-ENVOY-ORIGINAL-PATH?:PATH)%'
            # Upstream cluster to which the upstream host belongs to
            upstreamName: '%UPSTREAM_CLUSTER%'
            # Request start time including milliseconds.
            systemTime: '%START_TIME%'
            # Unique tracking ID
            requestId: '%REQ(X-REQUEST-ID)%'
          path: /dev/stdout
```

`kubectl -n gloo-system edit gateway`{{execute}}

Now make a request:
`curl -s $(glooctl proxy url)/get | jq`{{execute}}

And check the logs:
`kubectl logs -n gloo-system deployment/gateway-proxy-v2 | grep '^{' | jq`{{execute}}

Lets add the pod name and the endpoint url to the logs:

```
            requestId: '%REQ(X-REQUEST-ID)%'
            # The 'pod' dynamic metadata entry that is set by the Gloo transformation filter
            pod_name: '%DYNAMIC_METADATA(io.solo.transformation:pod_name)%'
            # The 'error' dynamic metadata entry that is set by the Gloo transformation filter
            endpoint_url: '%DYNAMIC_METADATA(io.solo.transformation:endpoint_url)%'
```

`kubectl -n gloo-system edit gateway`{{execute}}

Now add a transformation to the virtual service by adding dynamicMetadataValues to the responseTransformation:

```
        responseTransformation:
          transformationTemplate:
            dynamicMetadataValues:
            # Set a dynamic metadata entry named "pod"
            - key: 'pod_name'
              value:
                # The POD_NAME env is set by default on the gateway-proxy-v2 pods
                text: '{{ env("POD_NAME") }}'
            # Set a dynamic metadata entry using an request body attribute
            - key: 'endpoint_url'
              value:
                # The "url" attribute in the JSON response body
                text: '{{ url }}'
```

`kubectl -n gloo-system edit virtualservice echo`{{execute}}

Make another request:
`curl -s $(glooctl proxy url)/get | jq`{{execute}}

And check the logs. Now you should see entries for pod_name and entrypoint_url:
`kubectl logs -n gloo-system deployment/gateway-proxy-v2 | grep '^{' | jq`{{execute}}
