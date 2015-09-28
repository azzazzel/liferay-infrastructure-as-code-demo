etcdctl set /mycluster/haproxy/config << EOF

global
  maxconn 256

defaults
  mode http
  timeout connect 5000ms
  timeout client 50000ms
  timeout server 50000ms

frontend http-in
  bind *:80

  # Define hosts
  acl host_1 hdr(host) -i 1.liferay.cloud
  acl host_2 hdr(host) -i 2.liferay.cloud

  ## figure out which one to use
  use_backend liferay1 if host_1
  use_backend liferay2 if host_2

  default_backend liferay

backend liferay
  balance roundrobin
  cookie SERVERID insert indirect nocache
  server liferay1 10.100.0.101 maxconn 32 cookie s1
  server liferay2 10.100.0.102 maxconn 32 cookie s2

backend liferay1
  server liferay1 10.100.0.101 maxconn 32

backend liferay2
  server liferay2 10.100.0.102 maxconn 32

listen stats :81
    mode http
    stats enable
    stats hide-version
    stats realm Haproxy\ Statistics
    stats uri /
    stats auth demo:demo

EOF