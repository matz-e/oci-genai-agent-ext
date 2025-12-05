FROM ubuntu:latest

ARG USER=benutzer
ARG PASSWORD=phrase-de-passage

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Apache2 utils needed for htpasswd
RUN apt-get update \
 && apt-get install -y apache2-utils git nginx

RUN mkdir /appli
COPY agent.py app.py pyproject.toml /appli
COPY nginx.conf /etc/nginx/sites-enabled/default
WORKDIR /appli

# As of Dec 2025, not all packages are available as binaries for Python 3.14
RUN uv sync --python=cpython313

RUN apt-get purge -y git \
 && apt-get autoremove -y \
 && rm -rf /var/lib/apt/lists/*

EXPOSE 80
HEALTHCHECK CMD curl --fail http://localhost/_stcore/health

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
