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

import logging
import os

import mesop as me
from constants import GEMINI_TITLE_PREFIX, PAGE_TITLE_SUFFIX
from google import genai
from mesop_components import migration_blocker_analysis_body, vertex_gemini_header
from mesop_event_handlers import on_load
from mesop_state import MesopState

logging.basicConfig(level=logging.DEBUG)


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
    migration_blocker_analysis_body()
