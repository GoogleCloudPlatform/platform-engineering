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

from typing import List

import mesop as me
from constants import GEMINI_TITLE_PREFIX, PAGE_TITLE_SUFFIX
from mesop_event_handlers import on_blur_app_repository_url, on_selection_change_model
from mesop_styles import (
    _STYLE_MAIN_BODY,
    _STYLE_MAIN_HEADER,
    _STYLE_TITLE_BOX,
    GEMINI_TEXT_GRADIENT,
)
from vertex_ai import get_available_models


@me.component
def vertex_gemini_header() -> None:
    """Vertex AI Gemini Header component"""
    with me.box(style=_STYLE_MAIN_HEADER):
        with me.box(style=_STYLE_TITLE_BOX):
            with me.box(
                style=me.Style(
                    display="flex", flex_direction="row", gap=5, align_content="center"
                ),
            ):
                me.text(
                    GEMINI_TITLE_PREFIX,
                    type="headline-5",
                    style=GEMINI_TEXT_GRADIENT,
                )
                me.text(PAGE_TITLE_SUFFIX, type="headline-5")


@me.component
def migration_blocker_analysis_body() -> None:
    """Migration blocker analysis body Mesop component"""
    with me.box(style=_STYLE_MAIN_BODY):
        migration_blocker_analysis_input()
        with me.box():
            me.text("report")


@me.component
def migration_blocker_analysis_input() -> None:
    """Migration blocker analysis input Mesop component"""
    model_select_options = build_model_select_options()
    with me.box():
        me.select(
            appearance="outline",
            label="Gemini Model",
            on_selection_change=on_selection_change_model,
            options=model_select_options,
            multiple=False,
        )
        me.input(
            label="App source code repository URL",
            on_blur=on_blur_app_repository_url,
            type="url",
            required=True,
        )


def build_model_select_options() -> List[me.SelectOption]:
    select_options = []
    for model in get_available_models():
        select_options.append(me.SelectOption(label=model, value=model))
    return select_options
