#!/usr/bin/env bash
set -euo pipefail
APP=/opt/veil-player
SITE=/etc/nginx/sites-available/tiletribe-backend
test -f /etc/veil-player/backend.env
test -d /opt/veil-player-pilot/browsers
test ! -e /etc/apparmor.d/veil-player-pilot
env --chdir="$APP" npm ci --ignore-scripts --no-audit --no-fund
env --chdir="$APP" npm test
install -m 644 "$APP/deploy/apparmor.profile" /etc/apparmor.d/veil-player-browser
apparmor_parser -r /etc/apparmor.d/veil-player-browser
install -m 644 "$APP/deploy/veil-player.service" /etc/systemd/system/veil-player.service
install -m 644 "$APP/deploy/nginx.conf" /etc/nginx/snippets/veil-player.conf
systemctl daemon-reload
systemctl enable --now veil-player
for attempt in {1..15}; do
  if curl -fsS --unix-socket /run/veil-player/service.sock http://localhost/health; then break; fi
  sleep 1
done
curl -fsS --unix-socket /run/veil-player/service.sock http://localhost/health
backup="${SITE}.veil-player-backup-$(date -u +%Y%m%dT%H%M%SZ)"
cp -p "$SITE" "$backup"
python3 - "$SITE" <<'PY'
import pathlib,sys
path=pathlib.Path(sys.argv[1])
text=path.read_text()
include='    include /etc/nginx/snippets/veil-player.conf;'
marker='    server_name api.vexellab.com;'
if include not in text:
    if marker not in text: raise SystemExit('Expected API server block not found')
    path.write_text(text.replace(marker,marker+'\n'+include,1))
PY
if nginx -t; then
  systemctl reload nginx
else
  cp -p "$backup" "$SITE"
  exit 1
fi
curl -fsS --max-time 10 https://api.vexellab.com/veil-player/health
curl -fsS --max-time 10 https://api.vexellab.com/health/
curl -fsS --max-time 10 https://api.vexellab.com/chillara/api/health/
