# Gemini-powered migration blocker analysis frontend

## Deploy and run the application

### Google Cloud

### Docker Compose

Pre-requisites:

- Docker. Tested with version `28.0.4`
- Docker Compose. Tested with version `v2.34.0`

To run this application using Docker Compose, you do the following:

1. Open your shell.

2. Run the application using Docker Compose

    ```bash
    UID="$(id -u)" GID="$(id -g)" docker compose up --build --renew-anon-volumes
    ```
