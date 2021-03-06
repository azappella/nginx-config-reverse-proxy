#
upstream application {
   server localhost:8080;
}

#
server {
   listen [::]:80;
   listen 80;

   # listen on the base host
   server_name example.com;

   # disable cache
   # add_header Cache-Control "no-cache, must-revalidate, max-age=0";

   # and redirect to the app host (declared below)
   return 301 $scheme://app.$host$request_uri;
}

server {
   listen [::]:80;
   listen 80;

   # The host name to respond to
   server_name app.example.com;

   # disable cache
   # add_header Cache-Control "no-cache, must-revalidate, max-age=0";

   # change header values
   location / {
      proxy_pass http://application;
      proxy_pass_request_headers on;
      proxy_set_header Host $host;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_redirect $scheme://$host:8080 $scheme://$host:80;
   }

   # custom logs
   access_log /var/log/nginx/app-example.com.access.log;
   error_log /var/log/nginx/example.com.error.log;
}
