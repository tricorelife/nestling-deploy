#!/usr/bin/env bash
# Nestling 一键部署（静态二进制，零依赖，无需编译）
# 用法: DEEPSEEK_KEY=sk-xxx bash deploy.sh
set -e
KEY="${DEEPSEEK_KEY:-}"
[ -z "$KEY" ] && { read -rp "请输入 DeepSeek API Key (sk-开头): " KEY; }
[ -z "$KEY" ] && { echo "需要 DeepSeek Key"; exit 1; }
echo "▸ 下载静态二进制（3MB，零依赖）..."
mkdir -p /root/nestling
wget -q -O /root/nestling/nestling-cloud https://raw.githubusercontent.com/tricorelife/nestling-deploy/main/nestling-cloud
chmod +x /root/nestling/nestling-cloud
echo "▸ 写配置..."
cat > /root/nestling/config.toml <<CFG
listen = "0.0.0.0:8787"
db_path = "/root/nestling/cloud.db"
guest_credits_yuan = 20.0
[limits]
qps = 5
concurrency = 3
daily_cap_yuan = 50.0
[[upstreams]]
name = "deepseek"
base_url = "https://api.deepseek.com/v1"
api_key = "$KEY"
[[models]]
id = "deepseek-chat"
display_name = "DeepSeek V3"
upstream = "deepseek"
input_yuan_per_m = 2.0
output_yuan_per_m = 8.0
[[models]]
id = "deepseek-reasoner"
display_name = "DeepSeek R1 深度思考"
upstream = "deepseek"
input_yuan_per_m = 4.0
output_yuan_per_m = 16.0
CFG
echo "▸ 配置 systemd 常驻..."
cat > /etc/systemd/system/nestling.service <<'SVC'
[Unit]
Description=Nestling
After=network.target
[Service]
ExecStart=/root/nestling/nestling-cloud --config /root/nestling/config.toml serve
Restart=always
RestartSec=3
WorkingDirectory=/root/nestling
[Install]
WantedBy=multi-user.target
SVC
systemctl daemon-reload
systemctl enable --now nestling
sleep 2
echo ""
echo "======================================"
echo "服务状态: $(systemctl is-active nestling)"
echo "健康检查: $(curl -s localhost:8787/health)"
echo "邀请码（每个¥20）:"
/root/nestling/nestling-cloud --config /root/nestling/config.toml invite create --credits 20 --count 3
echo "桌面端/客户端填: http://$(curl -s -4 ifconfig.me 2>/dev/null):8787"
echo "======================================"
