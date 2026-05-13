# Production-style web process (e.g. Railway when not using Dockerfile).
# HTTP_PORT = platform PORT; Puma uses Thruster default TARGET_PORT (3000).
web: /bin/sh -c 'export HTTP_PORT="${PORT:-80}"; exec ./bin/thrust ./bin/rails server'
