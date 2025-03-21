'''
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
'''
from flask import Flask, render_template
import os

app = Flask(__name__)

def get_config_data():
    """Retrieves data from environment variables, simulating ConfigMap data."""
    return {
        "HEADER_TITLE": os.environ.get("HEADER_TITLE", "My Application"),
        "WELCOME_MESSAGE": os.environ.get("WELCOME_MESSAGE", "Hello from GKE!"),
        "IS_CONFIG": os.environ.get("IS_CONFIG","Unknown")
    }

@app.route("/")
def hello():
    """Renders the main page, injecting ConfigMap data."""
    config_data = get_config_data()
    return render_template("index.html", config_data=config_data)

if __name__ == "__main__":
    debug_mode = os.environ.get("FLASK_DEBUG", "False").lower() == "true"
    app.run(host="0.0.0.0", port=8080, debug=debug_mode)