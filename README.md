# SIEM → Google Drive Archiver

โปรแกรมสำเร็จรูปสำหรับ Export/Archive/Backup **log จาก SIEM ใด ๆ** ไปเก็บระยะยาวบน Google Drive  
รองรับทั้ง **mount โฟลเดอร์ (rclone mount)** หรือ **อัปโหลดตรง (rclone copy)**  
License: Apache-2.0

## คุณสมบัติ
- Export จาก **SIEM** ด้วยคำสั่งที่ผู้ใช้กำหนดเอง (`SIEM_EXPORT_CMD`)
- บีบอัด (`gzip`), ตรวจสอบ `SHA256`, (ตัวเลือก) เข้ารหัส `gpg`
- โครงสร้างโฟลเดอร์ `YYYY/MM`, ตั้งค่า `RETENTION_DAYS`
- ทำงานอัตโนมัติด้วย `systemd timer`
- ไม่พึ่งโค้ดซับซ้อน — shell script ล้วน

## โครงสร้างโปรเจกต์
```
siem-gdrive-archiver/
 ├─ LICENSE
 ├─ NOTICE
 ├─ README.md
 ├─ config.env
 ├─ install.sh
 ├─ run_backup.sh
 ├─ rclone-mount.service
 ├─ siem-gdrive-backup.service
 └─ siem-gdrive-backup.timer
```

## การติดตั้ง (Linux)
1) ติดตั้ง [rclone](https://rclone.org/install/) และตั้งค่า remote ชื่อ `gdrive`
   ```bash
   rclone config   # ทำ OAuth และตั้ง remote = gdrive
   ```
2) แก้ไขไฟล์ `config.env`
   - ตั้งค่า `SIEM_EXPORT_CMD` ให้เป็นคำสั่งที่รันแล้ว **ส่งออก log ไปที่ stdout**
   - ตั้งค่า `EXPORT_FORMAT` (`csv` หรือ `json`)
   - เลือก `UPLOAD_MODE=mount` หรือ `rclone_copy`
3) ติดตั้งบริการและตั้งเวลา
   ```bash
   sudo bash install.sh
   ```
4) ตรวจสอบสถานะและลองรันทันที
   ```bash
   systemctl status rclone-mount
   systemctl status siem-gdrive-backup.timer
   systemctl start siem-gdrive-backup.service
   journalctl -u siem-gdrive-backup -f
   ```

## ตัวอย่างการตั้งค่า `SIEM_EXPORT_CMD`
- **Splunk (ผ่าน CLI)**  
  ```bash
  SIEM_EXPORT_CMD='/opt/splunk/bin/splunk search "search index=main earliest=-1d@d latest=@d" -maxout 0 -output csv -auth ${SIEM_USERNAME}:${SIEM_PASSWORD}'
  EXPORT_FORMAT="csv"
  ```
- **Elastic (Elasticsearch REST API)** — ต้องมีไฟล์ query JSON และ `jq` แปลงผลลัพธ์
  ```bash
  SIEM_EXPORT_CMD='curl -s -u ${SIEM_USERNAME}:${SIEM_PASSWORD} -H "Content-Type: application/json" -X POST "https://ES_HOST:9200/myindex/_search?scroll=1m&size=1000" -d @/etc/siem-archiver/query.json | jq -r ".hits.hits[]._source"'
  EXPORT_FORMAT="json"
  ```
- **IBM QRadar (Ariel Query via CLI/REST)** — ให้ตั้งเป็นสคริปต์ที่ echo ผลลัพธ์ JSON/CSV ออก stdout
- **ArcSight/Other SIEM** — ทำ wrapper script ที่ไปเรียก API/CLI แล้ว pipe ออกทาง stdout

> เงื่อนไขหลัก: **คำสั่งต้องส่งออกข้อมูลผ่าน stdout** เพื่อให้สคริปต์บันทึกลงไฟล์ได้

## คอนฟิกสำคัญใน `config.env`
- `SIEM_EXPORT_CMD` — คำสั่งดึง log จาก SIEM (stdout)
- `SIEM_USERNAME`, `SIEM_PASSWORD`, `SIEM_TOKEN` — ใส่เมื่อจำเป็น (จะถูกแทนค่าใน command)
- `EXPORT_FORMAT` — `csv` หรือ `json`
- `WORKDIR` — โฟลเดอร์ทำงานชั่วคราวบนเครื่อง
- `MOUNT_POINT`, `REMOTE_SUBDIR`, `RCLONE_REMOTE`
- `UPLOAD_MODE` — `mount` (ต้องมี rclone mount) หรือ `rclone_copy`
- `COMPRESS`, `ENCRYPT`, `GPG_RECIPIENT`
- `RETENTION_DAYS`
- `BACKUP_SCHEDULE` — ใช้กับ systemd timer (`OnCalendar`)

## ความปลอดภัย
- เก็บความลับ (user/pass/token) ไว้ใน `config.env` ที่สิทธิ์ `600`
- ใช้ `GPG` เข้ารหัสก่อนเก็บลง Cloud ได้
- รองรับการใช้ token แทนรหัสผ่าน และการ export โดยอ่านจากไฟล์ credential

## Troubleshooting
- ดูบันทึก:
  ```bash
  journalctl -u siem-gdrive-backup -e
  ```
- ทดสอบ rclone:
  ```bash
  rclone ls gdrive:
  ```
- ตรวจการ mount:
  ```bash
  mount | grep gdrive
  ```

## License
โครงการนี้เผยแพร่ภายใต้สัญญาอนุญาต **Apache License 2.0** — รายละเอียดดูที่ [LICENSE](./LICENSE).

## Notice
ดูไฟล์ [NOTICE](./NOTICE) สำหรับข้อความลิขสิทธิ์
