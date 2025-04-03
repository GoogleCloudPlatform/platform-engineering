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

import os
import mesop as me

from mesop_events import on_load
from mesop_components import vertex_gemini_header
from google import genai
from mesop_state import MesopState
from constants import GEMINI_TITLE_PREFIX, PAGE_TITLE_SUFFIX

# PROJECT_ID = os.environ.get("GOOGLE_CLOUD_PROJECT")  # Your Google Cloud Project ID
# LOCATION = os.environ.get("GOOGLE_CLOUD_REGION")  # Your Google Cloud Project Region
# client = genai.Client(vertexai=True, project=PROJECT_ID, location=LOCATION)


@me.page(
    path="/",
    title=f"{GEMINI_TITLE_PREFIX} {PAGE_TITLE_SUFFIX}",
    security_policy=me.SecurityPolicy(
        allowed_iframe_parents=["https://googlecloudplatform.github.io"]
    ),
    on_load=on_load,
)
def app() -> None:
    """Main Mesop App"""
    state = me.state(MesopState)
    # Main header
    vertex_gemini_header()
