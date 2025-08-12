Key Features
1. Automated SIEM Log Export
Extracts data directly from SIEM CLI using user-defined SPL Queries.

Supports export in CSV or JSON format.

Can pull logs for specific time ranges (daily, weekly, monthly, or custom periods).

Works with Scheduled Searches in SIEM or runs ad-hoc queries via CLI.

2. Compression & Encryption
Supports file compression with gzip to reduce storage size.

Optional encryption with GPG Public Key for secure archival.

Automatically generates SHA256 checksums to ensure file integrity.

3. Google Drive Integration
Mount Google Drive as a local folder using rclone mount for direct file operations.

Or choose Direct Upload mode via rclone copy without mounting.

Customizable folder structure in Google Drive (e.g., SIEM-archive/YYYY/MM/).

4. Retention Management
Configurable Retention Policy to automatically delete files older than a specified number of days.

Automatic cleanup of old logs on Google Drive (when using mount mode).

5. Fully Automated Scheduling
Uses systemd timers to run jobs automatically at scheduled times (default: daily at 01:10).

Prevents duplicate runs with lockfile mechanism.

Persistent scheduling — continues running after system reboots.

6. Flexible Configuration
All settings are stored in a single config.env file for easy editing.

Configurable parameters include:

SIEM CLI path

Authentication method (Token or Username/Password)

SPL Query for log selection

Export format (csv / json)

Upload mode (mount or rclone_copy)

Compression and encryption options

Retention days

Backup schedule

7. Security-Oriented
Supports Splunk Token authentication to avoid storing plaintext passwords.

Allows file permission restrictions (chmod 600) for sensitive configs.

GPG encryption ensures secure transfer and storage of logs.

8. Minimal Dependencies
Requires only bash, rclone, gzip, and optionally gpg.

No complex coding required — ready-to-use scripts.

9. Logging & Monitoring
View detailed execution logs via journalctl.

Error handling with logging to systemd logs.

Easily extendable for alerts via Email, Slack, or LINE Notify.

10. Cross-Environment Ready
Designed for Linux servers (Debian, Ubuntu, CentOS).

Easily adaptable to Docker environments.

Can be modified to run on Windows using PowerShell + Task Scheduler.
