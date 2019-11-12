## Expose External Service via Gloo Gateway

Create a secret used to access the AWS Lambda function:
`glooctl create secret aws --name lambda --access-key AKIAV7ELQIBSSFDZUC4P --secret-key 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`{{execute}}

Verify the secret was created:
`kubectl -n gloo-system get secret lambda`{{execute}}

Create the upstream:
`glooctl create upstream aws --name lambda --aws-secret-name lambda`{{execute}}

Verify the upstream is Accepted and that Gloo has detected the AWS Lambda functions available (e.g. uppercase):
`glooctl get upstream lambda`{{execute}}

Create the route:
`glooctl add route --name lambda --dest-name lambda --aws-function-name uppercase --path-exact /uppercase`{{execute}}

Verify the viritualservice is Accepted:
`glooctl get virtualservice lambda`{{execute}}

Let’s test the Route /boston-weather using curl. This should return "SOLO.IO":
`curl --header "Content-Type: application/octet-stream" --header "Content-Type: Accept: application/octet-stream" --data "\"solo.io\"" $(glooctl proxy url)/uppercase`{{execute}}
