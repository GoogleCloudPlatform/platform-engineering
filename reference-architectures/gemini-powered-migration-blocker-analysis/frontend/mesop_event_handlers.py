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

import mesop as me

from mesop_state import MesopState


def on_load(e: me.LoadEvent) -> None:
    """On load event"""
    state = me.state(MesopState)
    state.current_page = "/"
    me.set_theme_mode("system")


def on_selection_change_model(e: me.SelectSelectionChangeEvent):
    state = me.state(MesopState)
    state.vertex_ai_model_id = e.value
