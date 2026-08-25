# How we work on Day 1

Your trainer will give you an **access card** (not stored in this repo): AWS IAM user, console password, access keys, VS Code URL, and Linux password.

1. Open the **lab VS Code** URL for your login (`u01`–`u06`). Use **your** Linux user. Do not use someone else’s home folder.
2. In the VS Code terminal (Linux bash, not PowerShell):

```bash
cd ~
git clone <repo-url-from-card> adx-aws-training
cd adx-aws-training
```

If the trainer already cloned for you, just `cd ~/adx-aws-training` and `git pull`.

3. AWS console: https://410232017221.signin.aws.amazon.com/console — sign in as **IAM user** `u01` … `u06`, region **us-east-1**.
4. Configure the CLI in **your** terminal (keys from the card):

```bash
aws configure
```

5. Follow `Module_01_Amazon_S3/01_S3_to_ADX_Lab.md`. Bucket: `adx-log-ingestion-<your-login>`.
6. Azure / ADX: use the portal and cluster URL on the card. Database: `ADXTrainingDB_<your-login>`.

Do not commit keys, `.env`, or passwords.
