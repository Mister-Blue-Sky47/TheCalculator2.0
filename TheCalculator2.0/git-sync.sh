#!/bin/zsh

# In das Projektverzeichnis wechseln
cd "$(dirname "$0")"

echo "=== 1. Git Status prüfen ==="
git status

echo "\n=== 2. Alle Änderungen hinzufügen ==="
git add .

echo "\n=== 3. Commit erstellen ==="
read "commit_msg?Commit-Nachricht eingeben (Standard: 'Update'): "
if [ -z "$commit_msg" ]; then
  commit_msg="Update: Automatische Sicherung"
fi
git commit -m "$commit_msg"

echo "\n=== 4. Zu GitHub pushen ==="
git push origin main

echo "\n✔ Alles erledigt und sicher synchronisiert!"
