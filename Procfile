# Production-style web process (e.g. Railway when not using Dockerfile).
# HTTP_PORT = platform PORT; TARGET_PORT = internal Puma (default 3100).
web: /bin/sh -c 'export HTTP_PORT="${PORT:-80}" TARGET_PORT="${TARGET_PORT:-3100}"; exec ./bin/thrust ./bin/rails server'
