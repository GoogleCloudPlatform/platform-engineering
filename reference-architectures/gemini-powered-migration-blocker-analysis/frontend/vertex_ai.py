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

import json
import logging
import os

from constants import REPORT_TEMPLATES_PATH
from file_system import list_files_in_directory
from google import genai
from typing import Dict, List

# PROJECT_ID = os.environ.get("GOOGLE_CLOUD_PROJECT")  # Your Google Cloud Project ID
# LOCATION = os.environ.get("GOOGLE_CLOUD_REGION")  # Your Google Cloud Project Region
# client = genai.Client(vertexai=True, project=PROJECT_ID, location=LOCATION)

logger = logging.getLogger(__name__)


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


def get_available_report_templates() -> Dict[str, Dict[str, object]]:
    """Returns a map of report templates.

    This function returns a dict of report templates. Each element of the map is
    a tuple where the key is the report template id, and the value is the report
    template.

    Returns:
        Dict[str, Dict[str, object]]: A dict of report templates.
    """
    report_template_paths = list_files_in_directory(REPORT_TEMPLATES_PATH)

    report_templates = {}
    for template_path in report_template_paths:
        logger.debug("Loading report template from %s", template_path)
        with open(template_path, encoding="utf-8") as template_data:
            value = json.load(template_data)
            key = value["id"]
            logger.debug("Adding %s: %s", key, value)
            report_templates[key] = value
    logger.debug("Built report templates: %s", report_templates)
    return report_templates
