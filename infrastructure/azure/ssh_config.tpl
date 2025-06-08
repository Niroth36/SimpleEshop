Host simpleeshop-control-plane
  HostName ${control_plane_ip}
  User azureuser
  IdentityFile ~/.ssh/id_ed25519
  Port 22
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null

%{ for index, ip in worker_ips ~}
Host simpleeshop-worker-${index + 1}
  HostName ${ip}
  User azureuser
  IdentityFile ~/.ssh/id_ed25519
  Port 22
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null

%{ endfor ~}