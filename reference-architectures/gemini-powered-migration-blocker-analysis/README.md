# Gemini-powered migration blocker analysis

## Deploy and run the application

### Google Cloud

### Docker Compose

Pre-requisites:

- Docker. Tested with version `28.0.4`
- Docker Compose. Tested with version `v2.34.0`

To run this application using Docker Compose, you do the following:

1. Open your shell.

2. Clone this repository.

3. Change the working directory to the directory where you cloned this
   repository.

4. Change the working directory to
   `reference-architectures/gemini-powered-migration-blocker-analysis`:

    ```bash
    cd reference-architectures/gemini-powered-migration-blocker-analysis
    ```

5. Run the application using Docker Compose

    ```bash
    UID="$(id -u)" GID="$(id -g)" docker compose up --build --renew-anon-volumes
    ```
