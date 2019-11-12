## Expose External Service via Gloo Gateway

Create a static upstream pointing to the weather service host:
`glooctl create upstream static --name weather --static-hosts api.openweathermap.org`{{execute}}

Verify that the weather upstream is Accepted:
`glooctl get upstream`{{execute}}

Create the route:
`glooctl add route --name weather --path-exact /boston-weather --dest-name weather --prefix-rewrite "/data/2.5/weather?q=Boston&APPID=5b8354119b9b297f9d84de9d819adee2"`{{execute}}

Verify that the weather virtualservice is Accepted:
`glooctl get virtualservice`{{execute}}

Let’s test the route /boston-weather using curl. This should return a json result describing the Boston weather::
`curl $(glooctl proxy url)/boston-weather`{{execute}}
