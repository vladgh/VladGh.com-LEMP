server {

  server_name _ "";

  access_log  /var/log/nginx/$host.access.log;
  error_log   /var/log/nginx/error.log;

  root    /var/www;
  index   index.php index.html;

  ## Block bad bots
  if ($http_user_agent ~* (HTTrack|HTMLParser|libcurl|discobot|Exabot|Casper|kmccrew|plaNETWORK|RPT-HTTPClient)) {
    return 444;
  }

  ## Block certain Referers (case insensitive)
  if ($http_referer ~* (sex|vigra|viagra) ) {
    return 444;
  }

  ## Deny dot files:
  location ~ /\. {
    deny all;
  }

  ## Favicon Not Found
  location = /favicon.ico {
    access_log off;
    log_not_found off;
  }

  ## Robots.txt Not Found
  location = /robots.txt { 
    access_log off; 
    log_not_found off; 
  }

  location / {
    try_files $uri $uri/ index.php;
  }  

  location ~ \.php$ {
    include /etc/nginx/fastcgi.conf;
    fastcgi_pass unix:/var/run/php5-fpm.sock;
  }

  ### NginX Status
  location /nginx_status {
  stub_status on;
    access_log   off; 
  }

  ### FPM Status
  location ~ ^/(status|ping)$ {
    fastcgi_pass unix:/var/run/php5-fpm.sock;
    access_log      off;
  }

}
