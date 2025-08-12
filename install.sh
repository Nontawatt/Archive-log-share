#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${BASE_DIR}/config.env"

if [[ $EUID -ne 0 ]]; then
  echo "โปรดรันด้วย sudo หรือในสิทธิ์ root"
  exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "ไม่พบ config.env — โปรดแก้ไขคอนฟิกก่อนติดตั้ง"; exit 1
fi

# โหลดคอนฟิก
set -a; source "$CONFIG_FILE"; set +a

# เตรียมโฟลเดอร์
mkdir -p "$WORKDIR" "$MOUNT_POINT"

# ตรวจ rclone
if ! command -v rclone >/dev/null 2>&1; then
  echo "ไม่พบ rclone — กำลังติดตั้ง..."
  curl -fsSL https://rclone.org/install.sh | bash
fi

# สร้าง systemd unit สำหรับ mount (ถ้าเลือกโหมด mount)
if [[ "${UPLOAD_MODE}" == "mount" ]]; then
cat >/etc/systemd/system/rclone-mount.service <<EOF
[Unit]
Description=Rclone mount for Google Drive
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/rclone mount ${RCLONE_REMOTE}: ${MOUNT_POINT} \
  --dir-cache-time 24h \
  --vfs-cache-mode writes \
  --vfs-cache-max-age 24h \
  --vfs-cache-max-size 2G \
  --poll-interval 15s \
  --umask 002 \
  --allow-other
Restart=on-failure
Environment=RCLONE_CONFIG=${HOME}/.config/rclone/rclone.conf

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable --now rclone-mount.service
fi

# ติดตั้ง service/timer สำหรับ backup
cp "${BASE_DIR}/run_backup.sh" /usr/local/bin/siem-gdrive-backup
chmod +x /usr/local/bin/siem-gdrive-backup

cat >/etc/systemd/system/siem-gdrive-backup.service <<EOF
[Unit]
Description=SIEM → Google Drive backup job
After=network-online.target rclone-mount.service
Wants=network-online.target

[Service]
Type=oneshot
EnvironmentFile=${BASE_DIR}/config.env
ExecStart=/usr/bin/env bash -c '/usr/local/bin/siem-gdrive-backup'
Nice=10
EOF

cat >/etc/systemd/system/siem-gdrive-backup.timer <<EOF
[Unit]
Description=Schedule for SIEM → Google Drive backup

[Timer]
OnCalendar=${BACKUP_SCHEDULE}
Persistent=true
Unit=siem-gdrive-backup.service

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now siem-gdrive-backup.timer

echo "ติดตั้งเสร็จสิ้น 🚀"
echo "- ตรวจสอบสถานะ: systemctl status siem-gdrive-backup.timer"
echo "- รันทันที: systemctl start siem-gdrive-backup.service"
