#!/usr/bin/env bash
set -uo pipefail

[ "$(id -u 2>/dev/null || echo 0)" != 0 ] && { echo "Ejecutalo como root: sudo bash install.sh"; exit 1; }

echo "=== Instalando Servidor BHTTP ==="

# Crear directorios
mkdir -p /usr/local/lib/bhttp

# Copiar archivos del repositorio actual al sistema
cp bhttp-server.py /usr/local/lib/bhttp/bhttp-server.py
chmod +x /usr/local/lib/bhttp/bhttp-server.py

cp bhttp.service /etc/systemd/system/bhttp.service

# Tuning de red TCP para evitar Connection Reset bajo carga
cat > /etc/sysctl.d/99-bhttp.conf << 'EOF'
net.core.somaxconn = 4096
net.core.netdev_max_backlog = 16384
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.ip_local_port_range = 1024 65535
fs.file-max = 1048576
net.ipv4.tcp_fastopen = 0
net.ipv4.tcp_tw_reuse = 0
net.ipv4.tcp_slow_start_after_idle = 1
net.ipv4.tcp_mtu_probing = 0
EOF
sysctl -p /etc/sysctl.d/99-bhttp.conf >/dev/null 2>&1 || true

# Asegurar Forwarding en SSH
sed -i 's/^[[:space:]]*#\?[[:space:]]*AllowTcpForwarding.*/AllowTcpForwarding yes/' /etc/ssh/sshd_config
systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true

# Habilitar y arrancar servicio
systemctl daemon-reload
systemctl enable bhttp.service
systemctl restart bhttp.service

echo "=== ¡Instalación completada con éxito! ==="
echo "El servidor BHTTP está activo en el puerto 90."
systemctl status bhttp --no-pager
