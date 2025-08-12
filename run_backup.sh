#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DEFAULT="${SCRIPT_DIR}/config.env"
if [[ -f "${CONFIG_DEFAULT}" ]]; then
  set -a; source "${CONFIG_DEFAULT}"; set +a
fi

LOCK_FILE="/var/lock/siem-gdrive-backup.lock"
exec 9>"$LOCK_FILE" || true
if ! flock -n 9; then
  echo "พบการทำงานซ้ำ ซักครู่ต่อไป"; exit 0
fi

LOG_TAG="[siem-archiver]"
DATE_STR="$(date +%F)"
TIME_STR="$(date +%H%M%S)"
YEAR=$(date +%Y)
MONTH=$(date +%m)

TARGET_DIR="${MOUNT_POINT}/${REMOTE_SUBDIR}/${YEAR}/${MONTH}"
LOCAL_DIR="${WORKDIR}/${YEAR}/${MONTH}"
mkdir -p "$LOCAL_DIR"

FILENAME="${FILENAME_PREFIX}-${DATE_STR}-${TIME_STR}.${EXPORT_FORMAT}"
LOCAL_FILE="${LOCAL_DIR}/${FILENAME}"

echo "$LOG_TAG เริ่มงานที่ $(date)"
echo "$LOG_TAG เรียกคำสั่ง export จาก SIEM"

# เตรียมคำสั่ง export
if [[ -z "${SIEM_EXPORT_CMD:-}" ]]; then
  echo "$LOG_TAG ไม่ได้ตั้งค่า SIEM_EXPORT_CMD ใน config.env"; exit 1
fi

# แทนค่า env ลงในคำสั่ง
CMD_EVAL=$(eval "echo \"${SIEM_EXPORT_CMD}\"")

# รันคำสั่งและเขียนลงไฟล์
bash -c "${CMD_EVAL}" > "${LOCAL_FILE}"

# บีบอัด
FINAL_FILE="${LOCAL_FILE}"
if [[ "${COMPRESS}" == "gzip" ]]; then
  gzip -f "${LOCAL_FILE}"
  FINAL_FILE="${LOCAL_FILE}.gz"
fi

# เข้ารหัสถ้าต้องการ
if [[ "${ENCRYPT}" == "gpg" ]]; then
  if ! command -v gpg >/dev/null 2>&1; then
    echo "$LOG_TAG ไม่พบ gpg — กำลังติดตั้ง"
    apt-get update && apt-get install -y gnupg || true
  fi
  gpg --yes --recipient "${GPG_RECIPIENT}" --output "${FINAL_FILE}.gpg" --encrypt "${FINAL_FILE}"
  rm -f "${FINAL_FILE}"
  FINAL_FILE="${FINAL_FILE}.gpg"
fi

# สร้าง checksum
sha256sum "${FINAL_FILE}" >> "${LOCAL_DIR}/CHECKSUMS-${DATE_STR}.txt"

# อัปโหลด/ย้ายไฟล์
if [[ "${UPLOAD_MODE}" == "mount" ]]; then
  mkdir -p "${TARGET_DIR}"
  mv "${FINAL_FILE}" "${TARGET_DIR}/"
  mv "${LOCAL_DIR}/CHECKSUMS-${DATE_STR}.txt" "${TARGET_DIR}/"
else
  RCLONE_PATH="${RCLONE_REMOTE}:${REMOTE_SUBDIR}/${YEAR}/${MONTH}"
  rclone mkdir "${RCLONE_PATH}" || true
  rclone copy "${FINAL_FILE}" "${RCLONE_PATH}"
  rclone copy "${LOCAL_DIR}/CHECKSUMS-${DATE_STR}.txt" "${RCLONE_PATH}"
fi

# ลบไฟล์เก่าตาม retention (เฉพาะกรณี mount)
if [[ "${UPLOAD_MODE}" == "mount" ]]; then
  find "${MOUNT_POINT}/${REMOTE_SUBDIR}" -type f -mtime +${RETENTION_DAYS} -print -delete || true
fi

echo "$LOG_TAG เสร็จสิ้นที่ $(date) — ไฟล์: $(basename "${FINAL_FILE}")"
