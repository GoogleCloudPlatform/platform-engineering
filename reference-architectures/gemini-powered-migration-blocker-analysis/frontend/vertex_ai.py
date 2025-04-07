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

# PROJECT_ID = os.environ.get("GOOGLE_CLOUD_PROJECT")  # Your Google Cloud Project ID
# LOCATION = os.environ.get("GOOGLE_CLOUD_REGION")  # Your Google Cloud Project Region
# client = genai.Client(vertexai=True, project=PROJECT_ID, location=LOCATION)

import os

from google import genai
from typing import List

# PROJECT_ID = os.environ.get("GOOGLE_CLOUD_PROJECT")  # Your Google Cloud Project ID
# LOCATION = os.environ.get("GOOGLE_CLOUD_REGION")  # Your Google Cloud Project Region
# client = genai.Client(vertexai=True, project=PROJECT_ID, location=LOCATION)


def get_available_models() -> List[str]:
    """Returns a list of currently available model names.

    This function provides a static list of model identifiers that
    are known to be available.

    Returns:
        List[str]: A list containing the names of the available models.
                   Example models: "gemini-2.0-flash-lite", "gemini-2.0-flash",
                   etc.
    """
    return [
        "gemini-2.0-flash-lite",
        "gemini-2.0-flash",
        "gemini-2.0-flash-thinking-exp-01-21",
    ]
