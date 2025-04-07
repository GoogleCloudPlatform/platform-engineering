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
from typing import Callable, Iterable, List, TypeVar

import mesop as me
from constants import GEMINI_TITLE_PREFIX, PAGE_TITLE_SUFFIX
from mesop_event_handlers import (
    on_blur_app_repository_url,
    on_selection_change_model,
    on_click_generate_report_button,
    on_selection_change_report_template,
)
from mesop_styles import (
    DEFAULT_BORDER,
    STYLE_GEMINI_TEXT_GRADIENT,
)

from vertex_ai import get_available_models, get_available_report_templates


logger = logging.getLogger(__name__)


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
    with me.box():
        me.select(
            appearance="outline",
            label="Gemini Model",
            on_selection_change=on_selection_change_model,
            options=build_model_select_options(),
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
        me.select(
            appearance="outline",
            label="Report template",
            on_selection_change=on_selection_change_report_template,
            options=build_report_template_select_options(),
            multiple=False,
        )


# Define a TypeVar for better type hinting
T = TypeVar("T")


def create_select_options(
    items: Iterable[T],
    label_extractor: Callable[[T], str],
    value_extractor: Callable[[T], str],
) -> List[me.SelectOption]:
    """
    Creates a list of SelectOption objects from an iterable of items.

    Args:
        items: An iterable of source items.
        label_extractor: A function that takes an item and returns the string
                         to be used as the SelectOption's label.
        value_extractor: A function that takes an item and returns the string
                         to be used as the SelectOption's value.

    Returns:
        A list of SelectOption objects.
    """
    select_options = []
    logger.debug(
        "Building SelectOptions list from %s",
        items,
    )
    for item in items:
        logger.debug("Processing item: %s", item)
        label = label_extractor(item)
        logger.debug("Label: %s", label)
        value = value_extractor(item)
        logger.debug("Value: %s", value)
        select_options.append(me.SelectOption(label=label, value=value))
    logger.debug("Built SelectOptions: %s", select_options)
    return select_options


def build_model_select_options() -> List[me.SelectOption]:
    return create_select_options(
        items=get_available_models(),
        label_extractor=lambda model: model,
        value_extractor=lambda model: model,
    )


def build_report_template_select_options() -> List[me.SelectOption]:
    report_templates = get_available_report_templates()
    return create_select_options(
        items=report_templates,
        label_extractor=lambda template: report_templates[template]["name"],
        value_extractor=lambda template: template,
    )
