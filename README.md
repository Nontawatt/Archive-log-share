# Archive-log-share
Feature หลัก
1. Automated Splunk Log Export
ดึงข้อมูลจาก Splunk CLI ตาม SPL Query ที่ผู้ใช้กำหนด

รองรับการ Export เป็น CSV หรือ JSON

ใช้ Scheduled Search ใน Splunk หรือให้ script รัน query เองผ่าน CLI

ดึงข้อมูลช่วงเวลาที่กำหนดได้ เช่น รายวัน, รายสัปดาห์, รายเดือน

2. Compression & Encryption
รองรับการบีบอัดไฟล์ด้วย gzip เพื่อลดขนาด

รองรับการเข้ารหัสไฟล์ด้วย GPG Public Key (เพื่อส่งไฟล์ไปเก็บแบบปลอดภัย)

สร้าง SHA256 Checksum อัตโนมัติ เพื่อให้ตรวจสอบความถูกต้องของไฟล์ได้

3. Google Drive Integration
Mount Google Drive เป็น Local Disk ด้วย rclone mount (ทำงานเหมือนโฟลเดอร์ปกติ)

หรือเลือกโหมด Direct Upload ด้วย rclone copy โดยไม่ต้อง mount

กำหนดโฟลเดอร์ปลายทางใน Google Drive ได้ เช่น splunk-archive/YYYY/MM/

4. Retention Management
ตั้งค่า Retention Policy (ลบไฟล์ที่เก่ากว่ากี่วัน)

ระบบลบไฟล์เก่าอัตโนมัติใน Google Drive (เมื่อใช้โหมด mount)

5. Fully Automated Scheduling
ใช้ systemd timer เพื่อรันงานอัตโนมัติตามเวลาที่ตั้ง เช่น ทุกวัน 01:10

ป้องกันการรันซ้ำด้วย Lockfile

ทำงานแม้ระบบ reboot เพราะ systemd จะ resume ได้

6. Flexible Configuration
ค่าทั้งหมดอยู่ใน ไฟล์ config.env แก้ไขได้ง่าย

ตั้งค่าพารามิเตอร์ได้ เช่น:

ที่อยู่ Splunk CLI

วิธี Auth (Token / Username+Password)

SPL Query

รูปแบบ Export (csv/json)

โหมดอัปโหลด (mount หรือ rclone_copy)

การบีบอัดและเข้ารหัส

Retention days

เวลา backup

7. Security-Oriented
รองรับการใช้ Splunk Token แทนรหัสผ่าน เพื่อลดความเสี่ยง

สามารถจำกัดสิทธิ์ไฟล์ config.env (chmod 600)

รองรับการเข้ารหัส GPG ก่อนส่งขึ้น Cloud

8. Minimal Dependency
ใช้เพียง bash, rclone, gzip, และ (ถ้าต้องการ) gpg

ไม่ต้องมีโปรแกรมเมอร์มาดูแล — script พร้อมใช้

9. Logging & Monitoring
ใช้ journalctl ดู log การทำงานย้อนหลังได้

แจ้ง error ใน console/systemd log เมื่อ export หรือ upload ล้มเหลว

เหมาะกับการนำไปต่อยอดแจ้งเตือนผ่าน Email, Slack, LINE Notify (soon)

10. Cross-Environment Ready
ออกแบบให้ติดตั้งได้บน Linux Server ทั่วไป (Debian, Ubuntu, CentOS)

สามารถต่อยอดทำเป็น Docker container ได้ง่าย

ดัดแปลงให้รันบน Windows ผ่าน PowerShell + Task Scheduler ได้
