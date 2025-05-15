# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

import os
import asyncio
from google.cloud import storage
from google.cloud import firestore
from google.cloud.firestore import Query
from google.cloud.firestore import AsyncClient
from google.api_core import exceptions as google_exceptions
from fastapi import UploadFile, HTTPException
from typing import Optional, Tuple, List


try:
    from models import ReportMetadata, ReportSummary
except ImportError:
    print("Warning: Could not import ReportMetadata from models. Ensure models.py is accessible.")
    class ReportMetadata: pass # Dummy class
    class ReportSummary: pass # Dummy class

# Initialize the GCS client.
# Doing this globally can reuse the connection.
# Ensure GOOGLE_APPLICATION_CREDENTIALS is set in your environment.
try:
    storage_client = storage.Client()
except Exception as e:
    print(f"Warning: Failed to initialize Google Cloud Storage client. Ensure credentials are set.")
    print(f"Error: {e}")
    storage_client = None


try:
    # Use AsyncClient for native asyncio support
    firestore_client = firestore.AsyncClient()
    FIRESTORE_COLLECTION = "MigrationReport"
except Exception as e:
    print(f"Warning: Failed to initialize Google Cloud Firestore Async client. Ensure credentials are set and API is enabled in Datastore mode.")
    print(f"Error: {e}")
    firestore_client = None



# --- get GCS blob metadata ---
async def get_gcs_blob_metadata(blob_name: str, bucket_name: str) -> Optional[Tuple[str, str]]:
    """
    Fetches the content type and GCS URI for a blob.

    Args:
        blob_name: The full path to the blob within the bucket (e.g., "docs/report1/file.pdf").
        bucket_name: The name of the GCS bucket.

    Returns:
        A tuple containing (gcs_uri, content_type) or None if blob not found or error.
    """
    if not storage_client:
        print("Error: Storage client not initialized.")
        return None
    if not bucket_name or not blob_name:
        print("Error: Missing bucket name or blob name.")
        return None

    try:
        bucket = storage_client.bucket(bucket_name)
        # Run synchronous get_blob in executor
        loop = asyncio.get_running_loop()
        blob = await loop.run_in_executor(None, bucket.get_blob, blob_name)

        if blob:
            gcs_uri = f"gs://{bucket_name}/{blob_name}"
            print(f"Fetched metadata for {gcs_uri}, content type: {blob.content_type}")
            return (gcs_uri, blob.content_type)
        else:
            print(f"Warning: Blob '{blob_name}' not found in bucket '{bucket_name}'.")
            return None
    except google_exceptions.Forbidden:
        print(f"Error: Permission denied to access blob gs://{bucket_name}/{blob_name}.")
        return None
    except Exception as e:
        print(f"An unexpected error occurred fetching metadata for {blob_name}: {e}")
        return None


async def upload_to_gcs(
    file: UploadFile,
    destination_blob_name: str,
    bucket_name: str
) -> Optional[str]:
    """
    Uploads an FastAPI UploadFile object to a GCS bucket.

    Args:
        file: The FastAPI UploadFile object to upload.
        destination_blob_name: The desired name for the object in GCS (e.g., "docs/report1/file.txt").
        bucket_name: The name of the GCS bucket.

    Returns:
        The GCS URI (gs://<bucket_name>/<blob_name>) of the uploaded file, or None if upload fails.
    """
    if not storage_client:
        print("Error: Storage client not initialized.")
        return None
    if not file or not file.filename:
        print("Error: Invalid file provided for upload.")
        return None

    try:
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(destination_blob_name)

        # Read the entire file content asynchronously
        contents = await file.read()
        await file.seek(0) # Reset file pointer in case it's needed again

        # Get the content type if provided
        content_type = file.content_type

        
        loop = asyncio.get_running_loop()
        await loop.run_in_executor(
            None,  # Uses the default thread pool executor
            lambda: blob.upload_from_string(contents, content_type=content_type)
        )

        gcs_uri = f"gs://{bucket_name}/{destination_blob_name}"
        print(f"Successfully uploaded {file.filename} to {gcs_uri}")
        return gcs_uri

    except google_exceptions.NotFound:
        print(f"Error: Bucket '{bucket_name}' not found.")
        return None
    except google_exceptions.Forbidden:
        print(f"Error: Permission denied to upload to gs://{bucket_name}/{destination_blob_name}.")
        print("Ensure the service account has 'Storage Object Creator' role on the bucket.")
        return None
    except Exception as e:
        print(f"An unexpected error occurred during GCS upload: {e}")
        # re-raise for the endpoint to catch or handle differently
        return None
    finally:
        # close temp handle
        await file.close()

# --- Firestore Functions (using AsyncClient) ---

async def save_report_metadata(metadata: ReportMetadata):
    """Saves the initial report metadata to Firestore (Datastore mode)."""
    if not firestore_client:
        print("Error: Firestore client not initialized.")
        raise ConnectionError("Firestore client not available")
    if not isinstance(metadata, ReportMetadata):
        print(f"Error: Invalid metadata type provided: {type(metadata)}")
        raise TypeError("Invalid metadata type provided")

    try:
        # Get a reference to the document
        doc_ref = firestore_client.collection(FIRESTORE_COLLECTION).document(metadata.report_id)

        # Convert Pydantic model to dict
        entity_data = metadata.model_dump(exclude_none=True)

        # Convert HttpUrl to string for storage
        if 'github_repo_url' in entity_data:
            entity_data['github_repo_url'] = str(entity_data['github_repo_url'])

        await doc_ref.set(entity_data)
        print(f"Successfully saved metadata for report {metadata.report_id} to Firestore.")

    except Exception as e:
        print(f"Error saving metadata for report {metadata.report_id} to Firestore: {e}")
        raise

async def get_report_metadata(report_id: str) -> Optional[ReportMetadata]:
    """Fetches report metadata from Firestore (Datastore mode) by report_id."""
    if not firestore_client:
        print("Error: Firestore client not initialized.")
        return None

    try:
        doc_ref = firestore_client.collection(FIRESTORE_COLLECTION).document(report_id)

        snapshot = await doc_ref.get()

        if snapshot.exists:
            print(f"Successfully fetched metadata for report {report_id} from Firestore.")
            entity_dict = snapshot.to_dict()
            try:
                # Convert dict back to Pydantic model
                # Handle potential missing fields if schema changes
                metadata = ReportMetadata(**entity_dict)
                return metadata
            except Exception as validation_error:
                 print(f"Error converting Firestore data to ReportMetadata for {report_id}: {validation_error}")
                 print(f"Firestore data: {entity_dict}")
                 return None
        else:
            print(f"Report {report_id} not found in Firestore.")
            return None

    except Exception as e:
        print(f"Error fetching metadata for report {report_id} from Firestore: {e}")
        return None


# --- Update the report in firestore ---
async def update_report_status(
    report_id: str,
    status: str,
    error: Optional[str] = None,
    summary: Optional[str] = None
):
    """
    Updates the status, error, and summary of a report in Firestore.
    (NON-TRANSACTIONAL VERSION)
    """
    if not firestore_client:
        print("Error: Firestore client not initialized.")
        raise ConnectionError("Firestore client not available")

    doc_ref = firestore_client.collection(FIRESTORE_COLLECTION).document(report_id)

    print(f"Attempting to update report {report_id} to status '{status}'...")

    try:
        # Prepare the data to update
        update_data = {
            'status': status,
            'updated_at': firestore.SERVER_TIMESTAMP, # Use server timestamp
        }
        if error is not None:
            # Firestore removes fields set to None during update if merge=True (default)
            # Explicitly handle setting/clearing the error message
            update_data['error_message'] = error
        # If error is None, we might want to remove the error_message field
        # else:
            # update_data['error_message'] = firestore.DELETE_FIELD # To remove field if error cleared

        if summary is not None:
            update_data['report_summary'] = summary

        # Perform a direct update (merge=True is default, updates fields or creates doc if non-existent)
        # Using update ensures we don't overwrite the whole document if it exists
        await doc_ref.update(update_data)

        print(f"Successfully updated report {report_id} to status '{status}' in Firestore.")

    except google_exceptions.NotFound:
         # This occurs if the document doesn't exist when calling update
         print(f"Error updating status: Report {report_id} not found.")
         # Re-raise standard FileNotFoundError for consistency
         raise FileNotFoundError(f"Report {report_id} not found during status update.")
    except Exception as e:
        print(f"Error updating status for report {report_id}: {e}")
        raise # Re-raise

# --- list reports ---
async def list_reports_metadata(skip: int = 0, limit: int = 20) -> List[ReportSummary]:
    """
    Fetches a paginated list of report summaries from Firestore, ordered by creation date.
    """
    if not firestore_client:
        print("Error: Firestore client not initialized.")
        return [] # Return empty list on error

    summaries: List[ReportSummary] = []
    print(f"Fetching reports from Firestore: skip={skip}, limit={limit}")
    try:
        # Create base query for the collection
        query = firestore_client.collection(FIRESTORE_COLLECTION)

        # Order by creation date, newest first
        # NOTE: This requires a Firestore index on 'created_at' descending.
        # Firestore will often provide a link in the error log to create it automatically
        # the first time this query runs if the index is missing.
        query = query.order_by("created_at", direction=Query.DESCENDING)

        # Apply pagination
        query = query.offset(skip)
        query = query.limit(limit)

        # Execute the query asynchronously
        stream = query.stream()
        async for doc_snapshot in stream:
            if doc_snapshot.exists:
                try:
                    # Convert Firestore doc to our Pydantic summary model
                    doc_data = doc_snapshot.to_dict()
                    # Ensure required fields are present for ReportSummary
                    summary = ReportSummary(
                        report_id=doc_snapshot.id, # Get ID from snapshot
                        github_repo_url=doc_data.get("github_repo_url", "N/A"), # Handle potential missing field
                        status=doc_data.get("status", "Unknown"),
                        created_at=doc_data.get("created_at") # Already datetime from Firestore
                        # Add other fields to ReportSummary if needed/available
                    )
                    summaries.append(summary)
                except Exception as e:
                    # Log error if a specific document fails conversion
                    print(f"Error converting Firestore document {doc_snapshot.id} to ReportSummary: {e}")
                    print(f"Document data: {doc_snapshot.to_dict()}")
            else:
                 # This shouldn't happen with stream normally, but good practice
                 print(f"Warning: Snapshot for {doc_snapshot.id} did not exist.")


        print(f"Successfully fetched {len(summaries)} report summaries.")
        return summaries

    except google_exceptions.FailedPrecondition as e:
        # Specific check for missing index error
        if "requires an index" in str(e).lower():
             print(f"Firestore Error: Query requires an index. Please check the console logs for a link to create it automatically: {e}")
             # You might see a message like:
             # "The query requires an index. You can create it here: https://console.firebase.google.com/..."
             # Return empty or raise a specific exception
             raise HTTPException(
                 status_code=status.HTTP_400_BAD_REQUEST,
                 detail=f"Database query requires an index. Check server logs for creation link. Error: {e}"
             ) from e
        else:
            # Handle other precondition failures
            print(f"Firestore query precondition error: {e}")
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Database query error: {e}") from e
    except Exception as e:
        print(f"An unexpected error occurred listing reports: {e}")
        # Optionally raise HTTPException here too
        return [] # Return empty list on other errors