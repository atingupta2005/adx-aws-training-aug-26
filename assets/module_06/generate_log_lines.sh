#!/usr/bin/env bash
# Module 06 — install/start nginx + httpd/apache and write a few access/auth lines.
set -euo pipefail
sudo dnf install -y nginx httpd 2>/dev/null || sudo apt-get install -y nginx apache2
sudo systemctl start nginx || true
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1/ || true
# httpd often cannot bind :80 while nginx is up — append a sample line instead of failing
if ! sudo systemctl start httpd 2>/dev/null; then
  sudo systemctl start apache2 2>/dev/null || true
fi
if [ -f /var/log/httpd/access_log ]; then
  echo "127.0.0.1 - - [$(date '+%d/%b/%Y:%H:%M:%S %z')] \"GET /index.html HTTP/1.1\" 200 612 \"-\" \"lab-curl\"" | sudo tee -a /var/log/httpd/access_log >/dev/null
elif [ -f /var/log/apache2/access.log ]; then
  echo "127.0.0.1 - - [$(date '+%d/%b/%Y:%H:%M:%S %z')] \"GET /index.html HTTP/1.1\" 200 612 \"-\" \"lab-curl\"" | sudo tee -a /var/log/apache2/access.log >/dev/null
fi
curl -s -o /dev/null http://127.0.0.1/ || true
if [ -f /var/log/secure ]; then
  echo "$(date '+%b %e %H:%M:%S') $(hostname) sshd[22]: Accepted publickey for ec2-user from 10.1.1.8 port 22 ssh2" | sudo tee -a /var/log/secure
elif [ -f /var/log/auth.log ]; then
  echo "$(date '+%b %e %H:%M:%S') $(hostname) sshd[22]: Accepted publickey for student from 10.1.1.8 port 22 ssh2" | sudo tee -a /var/log/auth.log
fi
echo "After Filebeat is running, curl http://127.0.0.1/ again so harvesters see new lines."
