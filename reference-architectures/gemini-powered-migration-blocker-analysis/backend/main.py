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
import uuid
import datetime
import asyncio
from fastapi import FastAPI, HTTPException, status, BackgroundTasks, UploadFile, File, Form
from typing import List, Optional
from dotenv import load_dotenv
from pydantic import HttpUrl
from pathlib import Path
import traceback
import json
from github_utils import get_repo_info

# TODO: Cleanup imports

from models import (
    CreateReportRequest,
    CreateReportResponse,
    ReportResponse,
    ReportMetadata,
    ReportSummary
)

from gcp_utils import (
    upload_to_gcs,
    save_report_metadata,
    get_report_metadata,
    update_report_status,
    list_reports_metadata
)

from gemini_utils import analyze_with_gemini

load_dotenv()

GCP_PROJECT_ID = os.getenv("GOOGLE_CLOUD_PROJECT")
GCS_BUCKET_NAME = os.getenv("GCS_BUCKET_NAME")
GEMINI_MODEL_NAME = os.getenv("GEMINI_MODEL_NAME", "gemini-2.0-flash")
GCP_LOCATION = os.getenv("GCP_LOCATION")
PROMPT_TEMPLATE_PATH = Path(__file__).parent / "prompt_template.md"


async def process_report_generation(
    report_id: str,
    github_repo_url: str, # Pass as string if coming from Form(...)
    target_platform: Optional[str],
    doc_gcs_uris: List[str] # List of GCS URIs obtained after upload
):
    """
    Background task using multimodal Gemini input, GitHub context,
    expecting JSON output, cleaning the response, parsing JSON,
    and performing non-transactional Firestore updates.
    """
    print(f"Starting background processing for report: {report_id}")
    repo_info: Dict[str, Optional[str]] = {} # Initialize repo_info dictionary

    # Ensure required config is available
    if not GCP_PROJECT_ID or not GCP_LOCATION or not GCS_BUCKET_NAME:
         print(f"Error processing report {report_id}: Missing runtime GCP config (Project, Location, or Bucket Name).")
         try:
             # Use non-transactional update
             await update_report_status(report_id, status="failed", error="Missing/invalid server configuration for GCP.")
         except Exception as update_e:
             print(f"Additionally, failed to update report status to 'failed': {update_e}")
         return # Stop processing

    try:
        # --- Pre-fetch Repo Info ---
        print(f"Fetching repository info for: {github_repo_url}")
        repo_info = await get_repo_info(str(github_repo_url)) # Ensure URL is string
        if repo_info.get("error"):
             print(f"Failed to get repository info: {repo_info['error']}")
             # Mark as failed if cloning/processing fails.
             await update_report_status(report_id, status="failed", error=repo_info["error"])
             return # Stop processing if repo info fails
        # --- End Repo Info Fetch ---

        # Update status to 'processing' (non-transactional)
        await update_report_status(report_id, status="processing")

        # TODO: This prompt templating needs to move to a combination of outout schema and system instructions

        # --- Load and Format TEXT Prompt from Template ---
        print(f"Loading prompt template from: {PROMPT_TEMPLATE_PATH}")
        if not PROMPT_TEMPLATE_PATH.is_file():
             print(f"Error: Prompt template file not found at {PROMPT_TEMPLATE_PATH}")
             await update_report_status(report_id, status="failed", error="Server configuration error: Prompt template missing.")
             return # Stop processing

        try:
            # Read the template file content
            prompt_template = PROMPT_TEMPLATE_PATH.read_text(encoding="utf-8")
        except Exception as file_read_e:
             print(f"Error reading prompt template file {PROMPT_TEMPLATE_PATH}: {file_read_e}")
             await update_report_status(report_id, status="failed", error="Server error: Could not read prompt template.")
             return

        # Prepare context for the text part of the prompt, including repo info
        prompt_context = {
            "target_platform": target_platform or 'Not Specified',
            "github_repo_url": str(github_repo_url),
            # Provide default messages if content is None or empty from repo_info
            "readme_content": repo_info.get("readme") or "README not found or empty.",
            "dependency_files_content": repo_info.get("dependencies") or "Dependency files not found or empty.",
            "dockerfile_content": repo_info.get("dockerfile") or "Dockerfile not found or empty.",
        }
        try:
             # Format the prompt using the template and context
             text_prompt_content = prompt_template.format(**prompt_context)
        except KeyError as format_e:
             print(f"Error formatting prompt template: Missing key {format_e}")
             await update_report_status(report_id, status="failed", error=f"Server configuration error: Invalid prompt template (missing key {format_e}).")
             return
        except Exception as format_e:
             print(f"Error formatting prompt template: {format_e}")
             await update_report_status(report_id, status="failed", error="Server configuration error: Could not format prompt template.")
             return
        # --- End Text Prompt Preparation ---


        # --- Call Gemini ---
        print(f"Calling Gemini model '{GEMINI_MODEL_NAME}' (expecting JSON output) for report {report_id}...")
        analysis_result_str = await analyze_with_gemini( # Store raw string result first
            text_prompt=text_prompt_content,
            gcs_uris=doc_gcs_uris,
            bucket_name=GCS_BUCKET_NAME,
            project_id=GCP_PROJECT_ID,
            location=GCP_LOCATION,
            model_name=GEMINI_MODEL_NAME
        )
        print(f"Gemini analysis completed for report {report_id}.")

        # Check if the result indicates an error from the Gemini util function
        if analysis_result_str.startswith("Error:"):
             print(f"Gemini analysis failed for report {report_id}: {analysis_result_str}")
             # Store the specific Gemini error message
             await update_report_status(report_id, status="failed", error=analysis_result_str)
             return # Stop processing

        # TODO: All of this cleaning of the repsonse can go away if we refactor to use
        # output schema instead

        # --- Clean, Parse JSON, and Update Firestore ---
        final_summary_data: Dict | str # Type hint for the data to be stored
        parse_error_msg: Optional[str] = None # To store specific JSON parse error

        # --- Clean the response string ---
        cleaned_analysis_str = analysis_result_str.strip() # Remove leading/trailing whitespace
        # Remove potential markdown code fences (```json ... ``` or ``` ... ```)
        if cleaned_analysis_str.startswith("```json"):
            cleaned_analysis_str = cleaned_analysis_str[len("```json"):].strip()
        elif cleaned_analysis_str.startswith("```"):
             cleaned_analysis_str = cleaned_analysis_str[len("```"):].strip()

        if cleaned_analysis_str.endswith("```"):
            cleaned_analysis_str = cleaned_analysis_str[:-len("```")].strip()
        # --- End Cleaning ---

        try:
            # Attempt to parse the *cleaned* result string as JSON
            parsed_json = json.loads(cleaned_analysis_str)
            final_summary_data = parsed_json # Store the dictionary if successful
            print(f"Successfully parsed Gemini response as JSON for report {report_id}.")
        except json.JSONDecodeError as json_err:
            print(f"Warning: Failed to parse Gemini response as JSON for report {report_id}. Error: {json_err}")
            # Log the cleaned string that failed parsing for debugging
            print(f"Storing raw response string instead. Cleaned response was:\n{cleaned_analysis_str[:500]}...")
            final_summary_data = analysis_result_str # Store the ORIGINAL raw string on failure
            parse_error_msg = f"Gemini output was not valid JSON after cleaning: {json_err}" # Set specific error message

        # Update Firestore with completed status and the parsed data (Dict) or original raw string (str)
        # If JSON parsing failed, update the error_message field as well
        await update_report_status(
            report_id,
            status="completed",
            summary=final_summary_data, # This will be Dict or the original str
            error=parse_error_msg # Will be None if parsing succeeded, or error string if failed
        )
        print(f"Successfully processed and saved report: {report_id} (JSON parsing {'succeeded' if isinstance(final_summary_data, dict) else 'failed'}).")

    except FileNotFoundError as fnf_err:
        # Catch specific error if update_report_status fails because doc deleted mid-process
         print(f"Error processing report {report_id}: Document not found during update. {fnf_err}")
         # No further status update possible if document is gone
    except Exception as e:
        # Catch-all for other unexpected errors during processing
        # Includes potential errors from get_repo_info if not caught internally
        print(f"Unexpected error processing report {report_id}: {e}")
        traceback.print_exc() # Log the full traceback for debugging
        try:
            # Avoid overwriting a specific error (like cloning failure) if it already exists
            if not repo_info.get("error"):
                await update_report_status(report_id, status="failed", error=f"Unexpected server error: {type(e).__name__}")
        except Exception as update_e:
            # Log if even updating status to failed doesn't work
            print(f"Additionally, failed to update report {report_id} status to 'failed': {update_e}")



# --- FastAPI App ---
app = FastAPI(
    title="Platform Migration Readiness Analyzer",
    description="Uses Google Gemini to analyze application platform migration readiness based on GitHub repo and documentation.",
    version="0.1.0",
)

# --- API Endpoints ---

@app.post("/reports", status_code=status.HTTP_202_ACCEPTED, response_model=CreateReportResponse)
async def create_report(
    background_tasks: BackgroundTasks,
    github_repo_url: HttpUrl = Form(...),
    target_platform: Optional[str] = Form(None),
    documentation_files: List[UploadFile] = File([], description="Upload documentation files (optional)")
):
    """
    Initiates a new analysis report.
    Accepts GitHub URL, target platform, and optional documentation files.
    """
    report_id = str(uuid.uuid4())
    doc_gcs_uris = []


    # --- File Upload Logic (to GCS) ---
    for doc_file in documentation_files:
        if doc_file.filename:  # Check if a file was actually uploaded
            # Sanitize filename
            safe_filename = os.path.basename(doc_file.filename).replace(" ", "_")
            blob_name = f"docs/{report_id}/{safe_filename}"  # Use a safe filename
            try:
                
                gcs_uri = await upload_to_gcs(
                    file=doc_file,
                    destination_blob_name=blob_name,
                    bucket_name=GCS_BUCKET_NAME  # Pass the bucket name from config
                )
                # --- Check if upload was successful ---
                if gcs_uri:
                    doc_gcs_uris.append(gcs_uri)
                else:
                    # Handle failed upload for this specific file
                    # Raise an exception to fail the whole request
                    raise HTTPException(
                        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                        detail=f"Failed to upload file {doc_file.filename} to GCS."
                    )

            except HTTPException as http_exc:
                # Re-raise HTTPExceptions directly
                raise http_exc
            except Exception as e:
                # Catch unexpected errors from upload_to_gcs or logic here
                print(f"An unexpected error occurred processing file {doc_file.filename}: {e}")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=f"Server error while processing file {doc_file.filename}."
                )
            # No finally block needed here, upload_to_gcs handles closing the file

    # --- Save Initial Metadata (to Datastore) ---
    metadata = ReportMetadata(
        report_id=report_id,
        github_repo_url=github_repo_url,
        target_platform=target_platform,
        documentation_gcs_uris=doc_gcs_uris,
        status="pending", # Initial status
        created_at=datetime.datetime.utcnow(),
        updated_at=datetime.datetime.utcnow()
    )
    try:
        await save_report_metadata(metadata)
    except Exception as e:
         print(f"Failed to save initial metadata for report {report_id}: {e}")
         raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to save report metadata.")


    # --- Trigger Background Task ---
    background_tasks.add_task(
        process_report_generation,
        report_id,
        str(github_repo_url), # Pass as string
        target_platform,
        doc_gcs_uris
    )

    return CreateReportResponse(
        report_id=report_id,
        message="Report generation initiated.",
        status_endpoint=f"/reports/{report_id}" # URL client can poll
    )

# --- List Reports Endpoint ---
@app.get("/reports", response_model=List[ReportSummary], tags=["Reports"])
async def list_reports(skip: int = 0, limit: int = 20):
    """
    Retrieves a list of previously generated migration analysis reports,
    ordered by creation date (newest first). Supports pagination.
    """
    if skip < 0:
        raise HTTPException(status_code=400, detail="Skip parameter cannot be negative.")
    if limit < 1 or limit > 100: # Example: enforce a max limit
        raise HTTPException(status_code=400, detail="Limit parameter must be between 1 and 100.")

    try:
        report_summaries = await list_reports_metadata(skip=skip, limit=limit)
        return report_summaries
    except HTTPException as http_exc:
        # Re-raise specific HTTP exceptions (like missing index) from the util function
        raise http_exc
    except Exception as e:
        # Catch unexpected errors from the utility function call
        print(f"Error calling list_reports_metadata: {e}")
        # Optionally log traceback here
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to retrieve report list.")

@app.get("/reports/{report_id}", response_model=ReportResponse)
async def get_report(report_id: str):
    """
    Retrieves the status and results of a specific report.
    """
    metadata = await get_report_metadata(report_id)
    if not metadata:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Report not found")

    # Depending on how you store the result (in metadata summary or separate GCS file)
    analysis_result = metadata.report_summary
    if metadata.status == "completed" and not analysis_result and metadata.report_content_gcs_uri:
        # TODO: Add logic here to fetch the full report content from GCS if needed
        # analysis_result = await download_from_gcs(metadata.report_content_gcs_uri)
        analysis_result = f"Full report stored at: {metadata.report_content_gcs_uri}" # Placeholder

    return ReportResponse(metadata=metadata, analysis_result=analysis_result)

# --- Running the App (for local development) ---
if __name__ == "__main__":
    import uvicorn
    import asyncio # Import asyncio for placeholder sleep
    print("Starting Uvicorn server...")
    uvicorn.run(app, host="0.0.0.0", port=8000)