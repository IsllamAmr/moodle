# Deploy Moodle With A Permanent Public URL (Railway + GitHub)

This gives you a stable URL tied to your GitHub repo with auto-deploy on push.

## 1) Push these files to GitHub

From your local repo:

```bash
git add Dockerfile .dockerignore docker/entrypoint.sh DEPLOY_RAILWAY.md
git commit -m "Add Railway deployment support for Moodle"
git push
```

## 2) Create Railway project from GitHub

1. Open Railway dashboard.
2. Create `New Project` -> `Deploy from GitHub Repo`.
3. Select this repository (`IsllamAmr/moodle`).

Railway will build and run the Dockerfile automatically.

## 3) Add MySQL service in the same project

1. In Railway project: `New` -> `Database` -> `MySQL`.
2. Keep it in the same project.

## 4) Set required environment variables on the Moodle service

Set these in the Moodle web service:

- `MOODLE_DB_TYPE=mariadb`
- `MOODLE_DB_HOST=${{MySQL.MYSQLHOST}}`
- `MOODLE_DB_NAME=${{MySQL.MYSQLDATABASE}}`
- `MOODLE_DB_USER=${{MySQL.MYSQLUSER}}`
- `MOODLE_DB_PASS=${{MySQL.MYSQLPASSWORD}}`
- `MOODLE_DATA_ROOT=/var/moodledata`
- `MOODLE_AUTO_INSTALL=true`
- `MOODLE_SITE_FULLNAME=My Moodle`
- `MOODLE_SITE_SHORTNAME=Moodle`
- `MOODLE_ADMIN_USER=admin`
- `MOODLE_ADMIN_PASS=ChangeThisToStrongPass123!`
- `MOODLE_ADMIN_EMAIL=admin@example.com`

After first deploy, set:

- `MOODLE_WWWROOT=https://<your-service-domain>`

Use the exact Railway public domain for your service.

## 5) Add persistent volume

Attach a volume to the Moodle web service:

- Mount path: `/var/moodledata`

This keeps Moodle files persistent across restarts.

## 6) Open your permanent link

Use your Railway public domain as your shareable permanent URL.

Any new push to GitHub can auto-redeploy.
