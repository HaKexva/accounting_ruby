# Production-style web process (e.g. Railway when not using Dockerfile).
# Thruster must listen on the same port the platform assigns (Railway sets PORT).
web: /bin/sh -c 'export HTTP_PORT="${PORT:-80}"; exec ./bin/thrust ./bin/rails server'
