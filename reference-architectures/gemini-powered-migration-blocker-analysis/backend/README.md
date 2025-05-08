# README.md

## Intro

## Running Locally in development

### .env

Create a .env file in the root of the project with the following contents,
making sure to replace the placeholder text:

```bash
GOOGLE_CLOUD_PROJECT=your-gcp-project
GCS_BUCKET_NAME=bucket-name-for-docs
GEMINI_MODEL_NAME=gemini-2.0-flash
GCP_LOCATION=region
```

### Prereqs / Dependencies

Prereqs include:

- A Google Cloud Project and credentials with access to the API's listed below
- A working python environemnt, tested with 3.12.3

This project uses uv for python environment and dependency management.

To get setup with `uv` after cloning the repo :

```bash
uv sync
source .venv/bin/activate
```

We provide a requirements.txt file for those that require `pip` , we generate it
automatically with :

```bash
uv export --format requirements-txt --no-hashes > requirements.txt
```

Environment management via `pip` is left to the user

Google Cloud API access is handled via
[ADC](https://cloud.google.com/docs/authentication/provide-credentials-adc) , so
you can either use the gcloud CLI if running
[locally](https://cloud.google.com/docs/authentication/set-up-adc-local-dev-environment)
:

```bash
export GOOGLE_CLOUD_PROJECT=<your-gcp-project>
gcloud config set project $GOOGLE_CLOUD_PROJECT
gcloud auth application-default login
```

or use a
[service account](https://cloud.google.com/docs/authentication/set-up-adc-attached-service-account)
if your environemnt supports it.

Enable the required API's in Google Cloud :

```bash
export GOOGLE_CLOUD_PROJECT=<your-gcp-project>
gcloud config set project "${GOOGLE_CLOUD_PROJECT}"
gcloud services enable firestore.googleapis.com
gcloud services enable datastore.googleapis.com
gcloud services enable aiplatform.googleapis.com
gcloud services enable storage.googleapis.com
```

Now you can start the development server with :

```bash
fastapi dev main.py
```

The development server will also host OpenAPI docs for the service at :
<http://127.0.0.1:8000/docs>

Once running, you can either test from that page or test with curl as follows :

Send a request to generate a new report using the sample documentation :

```bash
curl -X POST "http://127.0.0.1:8000/reports" \
     -H "accept: application/json" \
     -F "github_repo_url=https://github.com/dockersamples/example-voting-app/" \
     -F "documentation_files=@reference-architectures/gemini-powered-migration-blocker-analysis/sample-platform/docs/platform-doc.pdf"
```

Make a note of the reports staut_endpoint in the output

Once completed you can view the report with, make sure to replace
status_endpoint placeholder :

```bash
curl http://127.0.0.1:8000<status_endpoint>
```

If you have it installed you can also pipe the output to `jq` for readability.

```bash
curl http://127.0.0.1:8000<status_endpoint> | jq
```

## Build and run a container

A sample Dockerfile is provided, modify to suit your needs You can build a
container with :

```bash
docker build -t mesop-backend:latest .
```

You need to pass ENVARS to the container when it runs, you can use the .env file
mentioned above, you also need to inject your local gcloud ADC credentials into
the container, this example uses a bind mount and runs the container with your
local UID/GID so that the bind mount works correctly.

First create some local ENVARS, ADC should point at your local ADC file :

```bash
ADC=~/.config/gcloud/application_default_credentials.json \
USER_ID=$(id -u) \
GROUP_ID=$(id -g)
```

Then run the container with :

'''bash docker run -p 8000:8000 \
--user $USER_ID:$GROUP_ID \
--env-file .env \
-e GOOGLE_APPLICATION_CREDENTIALS=/home/backend/application_default_credentials.json
\
-v $ADC:/home/backend/application_default_credentials.json:ro \
mesop-backend:latest '''
