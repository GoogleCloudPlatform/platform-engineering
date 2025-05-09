# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Simple command line interface (CLI) tool to demonstrate function of the
sandboxes reference architecture.
"""

import argparse
from datetime import datetime, timedelta

from google.cloud import firestore


def create(project_id, system_project):
    # The `project` parameter is optional and represents which project the client
    # will act on behalf of. If not supplied, the client falls back to the default
    # project inferred from the environment.
    db = firestore.Client(project=system_project)

    now = datetime.now()
    deployment = {
        "_updateSource": "python",
        "status": "provision_requested",
        "projectId": project_id,
        "templateName": "empty-project",
        "deploymentState": {
            "budgetLimit": 100,
            "currentSpend": 0,
            "expiresAt": (now + timedelta(days=7)).strftime(
                "%B %-d, %Y at %-I:%-M:%-S.%f %p UTC-7"
            ),
        },
        "userId": "8ac69ead-bbb7-46f0-8cf7-b44140d1b77b",
        "createdAt": now.strftime("%B %-d, %Y at %-I:%-M:%-S.%f %p UTC-7"),
        "updatedAt": now.strftime("%B %-d, %Y at %-I:%-M:%-S.%f %p UTC-7"),
        "variables": {
            "billing_account": "<your_billing_id>",
            "name": project_id,
            "parent_folder": "folders/87523515960",
        },
        "auditLog": ["python_cli - Sandbox initial provision_request"],
    }
    db.collection("deployments").document(project_id).set(deployment)

    print("Your new sandbox is being created and will be available at:")
    print(f"https://console.cloud.google.com/welcome?project={project_id}")


def delete(project_id, system_project):
    # The `project` parameter is optional and represents which project the client
    # will act on behalf of. If not supplied, the client falls back to the default
    # project inferred from the environment.
    db = firestore.Client(project=system_project)

    deployment_ref = db.collection("deployments").document(project_id)
    deployment_ref.update(
        {
            "status": "delete_requested",
            "auditLog": firestore.ArrayUnion(
                ["python_cli - User requested delete of the sandbox."]
            ),
        }
    )


def list_sandboxes():
    print("list action not implemented")


def main():
    parser = argparse.ArgumentParser(
        description="Simple cli tool to interact with the sanboxes "
        "reference architecture."
    )
    parser.add_argument("action", help="supported actions are: create, delete, list")
    parser.add_argument("--project_id", "-p", help="project id to interact with")
    parser.add_argument(
        "--system",
        "-s",
        help="project id of the system project which has the state database",
    )
    args = parser.parse_args()

    match args.action:
        case "create":
            create(args.project_id, args.system)
        case "delete":
            delete(args.project_id, args.system)
        case "list":
            list_sandboxes()
        case _:
            print(f"Error: unknown action, {args.action}")


if __name__ == "__main__":
    main()
