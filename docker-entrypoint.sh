#!/usr/bin/env bash
set -e

# Provide defaults
: "${PORT:=8000}"
: "${LOG_LEVEL:=info}"
: "${FLASK_APP:=server:create_app}"
: "${RUN_MIGRATIONS:=false}"

# Export PORT for subprocesses
export PORT

# If requested, run Flask-Migrate database upgrade.
# This assumes 'flask db upgrade' will work with your app's env vars.
if [ "$RUN_MIGRATIONS" = "true" ] ; then
  echo ">>> Running migrations (flask db upgrade)..."
  # ensure FLASK_APP is set if your migrations rely on it
  export FLASK_APP="${FLASK_APP}"
  flask db upgrade
fi

# If a custom CMD provided a $PORT placeholder, replace it in the args
# But usually CMD uses static port 8000; the Procfile used $PORT — the runtime should provide it.
# Use exec so signals (SIGTERM) are handled correctly by Gunicorn.
exec "$@"
