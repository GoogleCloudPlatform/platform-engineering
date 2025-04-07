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
from mesop_event_handlers import (
    on_blur_app_repository_url,
    on_selection_change_model,
    on_click_generate_report_button,
)
from mesop_styles import (
    DEFAULT_BORDER,
    STYLE_GEMINI_TEXT_GRADIENT,
)
from vertex_ai import get_available_models


@me.component
def main_page() -> None:
    """Main page"""
    with me.box(
        style=me.Style(
            display="grid", grid_template_rows="auto auto 1fr auto", height="100%"
        )
    ):
        # Header
        with me.box(style=me.Style(padding=me.Padding.all(24))):
            vertex_gemini_header()

        migration_blocker_analysis_input()

        # Body
        with me.box(
            style=me.Style(
                display="grid", grid_template_columns="250px 1fr", height="100%"
            )
        ):
            with me.box(style=me.Style(padding=me.Padding.all(24), overflow_y="auto")):
                me.text("Sidebar")

            # Main content
            with me.box(style=me.Style(padding=me.Padding.all(24), overflow_y="auto")):
                me.text("Main Content")

        # Footer
        with me.box(style=me.Style(padding=me.Padding.all(24))):
            me.text("Footer")


@me.component
def vertex_gemini_header() -> None:
    """Vertex AI Gemini Header component"""
    with me.box(
        style=me.Style(
            border=DEFAULT_BORDER,
            padding=me.Padding.all(5),
        )
    ):
        with me.box(style=me.Style(display="inline-block")):
            with me.box(
                style=me.Style(
                    display="flex", flex_direction="row", gap=5, align_content="center"
                ),
            ):
                me.text(
                    GEMINI_TITLE_PREFIX,
                    type="headline-5",
                    style=STYLE_GEMINI_TEXT_GRADIENT,
                )
                me.text(PAGE_TITLE_SUFFIX, type="headline-5")


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
        me.button(
            label="Generate report",
            type="stroked",
            on_click=on_click_generate_report_button,
        )


def build_model_select_options() -> List[me.SelectOption]:
    select_options = []
    for model in get_available_models():
        select_options.append(me.SelectOption(label=model, value=model))
    return select_options
