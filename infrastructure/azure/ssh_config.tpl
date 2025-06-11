Host simpleeshop-control-plane
  HostName ${control_plane_ip}
  User azureuser
  IdentityFile ~/.ssh/azure_rsa
  Port 22
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null

%{ for index, ip in worker_ips ~}
Host simpleeshop-worker-${index + 1}
  HostName ${ip}
  User azureuser
  IdentityFile ~/.ssh/azure_rsa
  Port 22
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null

%{ endfor ~}