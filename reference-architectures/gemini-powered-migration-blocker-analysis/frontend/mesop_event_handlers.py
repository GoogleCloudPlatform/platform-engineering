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

import mesop as me
from mesop_state import MesopState

logger = logging.getLogger(__name__)


def on_load(e: me.LoadEvent) -> None:
    """On load event handler"""
    logger.debug("on_load mesop event handler. Path: %s", e.path)
    state = me.state(MesopState)
    state.current_page = e.path
    logger.debug("Set current page to: %s", state.current_page)
    me.set_theme_mode("system")


def update_mesop_state_event_handler(
    event_handler_name: str, state_attribute_name: str, e: me.events.MesopEvent
):
    logger.debug("%s mesop event handler", event_handler_name)
    state = me.state(MesopState)
    try:
        new_value = e.value
        # Use setattr to update the attribute dynamically by name
        setattr(state, state_attribute_name, new_value)
        logger.debug("Set state.%s to %s", state_attribute_name, new_value)
    except AttributeError as ae:
        # Event might not have a value or state lacks attribute
        logger.error(
            """Error in %s: Could not access value on event %s or attribute %s on Mesop
            state: %s""",
            event_handler_name,
            type(e),
            state_attribute_name,
            ae,
        )


def on_selection_change_model(e: me.SelectSelectionChangeEvent):
    """On selection change model event handler"""
    update_mesop_state_event_handler(__name__, "vertex_ai_model_id", e)


def on_selection_change_report_template(e: me.SelectSelectionChangeEvent):
    """On selection change report template event handler"""
    update_mesop_state_event_handler(__name__, "report_template", e)


def on_blur_app_repository_url(e: me.InputBlurEvent):
    """On blur repository URL event handler"""
    update_mesop_state_event_handler(__name__, "app_repository_url", e)


def on_click_generate_report_button(e: me.ClickEvent):
    """On generate report button click event handler"""
    logger.debug(
        "on click generate report button. key: %s, is_target: %s", e.key, e.is_target
    )
