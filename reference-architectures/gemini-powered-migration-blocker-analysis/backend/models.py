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

from pydantic import BaseModel, HttpUrl, Field
from typing import List, Optional, Dict
import datetime

class ReportMetadata(BaseModel):
    """Metadata stored in Datastore for each report."""
    report_id: str
    github_repo_url: HttpUrl
    target_platform: Optional[str] = None
    documentation_gcs_uris: List[str] = []
    status: str = "pending" # e.g., pending, processing, completed, failed
    created_at: datetime.datetime = Field(default_factory=datetime.datetime.utcnow)
    updated_at: datetime.datetime = Field(default_factory=datetime.datetime.utcnow)
    error_message: Optional[str] = None
    report_content_gcs_uri: Optional[str] = None # Optional: Store full report in GCS
    report_summary: Optional[Dict | str] = None # Store analysis result directly if not too large

class CreateReportRequest(BaseModel):
    """Request body for creating a new report."""
    github_repo_url: HttpUrl
    target_platform: Optional[str] = None
    # We'll handle file uploads separately or add fields later

class CreateReportResponse(BaseModel):
    """Response body after successfully initiating report creation."""
    report_id: str
    message: str
    status_endpoint: str # URL to check the report status

class ReportResponse(BaseModel):
    """Response body for retrieving a report."""
    metadata: ReportMetadata
    analysis_result: Optional[Dict | str] # Could be structured JSON or markdown text

class ReportSummary(BaseModel):
    """Basic info for listing reports."""
    report_id: str
    github_repo_url: HttpUrl
    status: str
    created_at: datetime.datetime