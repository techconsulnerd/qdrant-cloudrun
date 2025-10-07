# Qdrant on Google Cloud Run

This repository provides a template for deploying Qdrant to Google Cloud Run using Google Cloud Build.

## Prerequisites

Before you begin, you will need the following:

*   A Google Cloud Platform (GCP) project
*   The `gcloud` command-line tool installed and configured
*   The Google Cloud Build API enabled for your project
*   The Google Cloud Run API enabled for your project
*   The Google Artifact Registry API enabled for your project
*   The Google Secret Manager API enabled for your project
*   The Google Filestore API enabled for your project
*   The Serverless VPC Access API enabled for your project

## Deployment

To deploy the Qdrant service, you can use the provided Cloud Build configuration.

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/qdrant/qdrant-cloudrun.git
    cd qdrant-cloudrun
    ```

2.  **Set your GCP project ID:**

    ```bash
    export PROJECT_ID=[your-gcp-project-id]
    gcloud config set project $PROJECT_ID
    ```

3.  **Create the Serverless VPC Access Connector:**

    Create a Serverless VPC Access connector to allow Cloud Run to connect to your Filestore instance.

    ```bash
    gcloud compute networks vpc-access connectors create qdrant-vpc-connector \
      --network default \
      --region $_ZONE \
      --range 10.9.0.0/28
    ```

4.  **Create the Filestore Instance:**

    Create a Filestore instance to provide persistent storage for Qdrant.

    ```bash
    gcloud filestore instances create qdrant-filestore \
      --zone $_ZONE \
      --tier=BASIC_HDD \
      --file-share="name=qdrant_storage,capacity=1TB" \
      --network="name=default"
    ```

    Note: Filestore instance creation can take several minutes.

5.  **Create the Qdrant API Key Secret:**

    Create a secret in Google Secret Manager to store your Qdrant API key.

    ```bash
    export QDRANT_API_KEY=$(openssl rand -hex 32)
    echo -n "$QDRANT_API_KEY" | gcloud secrets create qdrant-api-key --data-file=-
    ```

    Grant the Cloud Build service account access to the secret.

    ```bash
    export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
    gcloud secrets add-iam-policy-binding qdrant-api-key \
      --member="serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com" \
      --role="roles/secretmanager.secretAccessor"
    ```

6.  **Submit the build to Google Cloud Build:**

    ```bash
    export FILESTORE_IP=$(gcloud filestore instances describe qdrant-filestore --zone $_ZONE --format='value(networks.ipAddresses)')
    gcloud builds submit --config cloudbuild.yaml --substitutions='_ZONE="us-central1",_AR_PATH="cloudbuild",_QDRANT_API_KEY_SECRET="qdrant-api-key",_VPC_CONNECTOR="qdrant-vpc-connector",_FILESTORE_IP="$FILESTORE_IP",_FILESTORE_SHARE="qdrant_storage"' .
    ```

    This command will build the Docker image, push it to the Google Artifact Registry, and deploy the service to Google Cloud Run.

## Accessing the Service

Once the deployment is complete, you can access the Qdrant service through the URL provided by Cloud Run.

You can find the service URL in the Google Cloud Console or by running the following command:

```bash
gcloud run services describe qdrant-cloudrun --platform managed --region $_ZONE --format 'value(status.url)'
```

## Substitutions

The `cloudbuild.yaml` file uses the following substitutions:

*   `_ZONE`: The GCP region where the service will be deployed. The default is `us-central1`.
*   `_AR_PATH`: The name of the Artifact Registry repository. The default is `cloudbuild`.
*   `_QDRANT_API_KEY_SECRET`: The name of the secret in Secret Manager that contains the Qdrant API key. The default is `qdrant-api-key`.
*   `_VPC_CONNECTOR`: The name of the Serverless VPC Access connector. The default is `qdrant-vpc-connector`.
*   `_FILESTORE_IP`: The IP address of the Filestore instance.
*   `_FILESTORE_SHARE`: The name of the file share on the Filestore instance. The default is `qdrant_storage`.

You can override these values by passing the `--substitutions` flag to the `gcloud builds submit` command.

## Configuration

The Qdrant configuration can be customized by editing the `config/production.yaml` file. For more information on the available configuration options, please refer to the [Qdrant documentation](https://qdrant.tech/documentation/guides/configuration/).