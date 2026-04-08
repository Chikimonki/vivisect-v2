#!/bin/bash
# deploy.sh - Deploy Vivisect to GCP

echo "[*] Packaging Vivisect for GCP..."

# Create deployment directory
mkdir -p deploy
cp -r web deploy/
cp -r lib deploy/
cp -r hooks deploy/
cp -r neural deploy/
cp vivisect.lua deploy/

# Create startup script
cat > deploy/start.sh << 'START'
#!/bin/bash
cd /opt/vivisect/web
nohup luajit server.lua > /var/log/vivisect.log 2>&1 &
echo $! > /var/run/vivisect.pid
echo "[+] Vivisect running on port 8080"
START

chmod +x deploy/start.sh

echo "[+] Package ready in ./deploy/"
echo "[*] Next: scp -r deploy/ your-gcp-instance:/opt/vivisect"
