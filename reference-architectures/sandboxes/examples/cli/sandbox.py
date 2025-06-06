# Copyright 2025 Google LLC
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

billing_account = "<your_billing_id>"
folder_id = "folders/<your_folder_id>"


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
        "userId": "user@example.com",
        "createdAt": now.strftime("%B %-d, %Y at %-I:%-M:%-S.%f %p UTC-7"),
        "updatedAt": now.strftime("%B %-d, %Y at %-I:%-M:%-S.%f %p UTC-7"),
        "variables": {
            "billing_account": billing_account,
            "project_id": project_id,
            "parent_folder": folder_id,
        },
        "auditLog": ["python_cli - Sandbox initial provision_request"],
    }
    db.collection("deployments").document(project_id).set(deployment)

    print("Your new sandbox is being created and will be available at:")
    print(f"https://console.cloud.google.com/welcome?project={project_id}")


def delete(project_id, system_project):
    # The `project` parameter is optional and represents which project the client
    # will operate on behalf of. If not supplied, the client falls back to the
    # default project inferred from the environment.
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


# Simple sanity checks to make sure users have set the required constants
def check_config():
    if billing_account == "<your_billing_id>":
        print(
            "ERROR: The billing account information must be updated before \
the cli can be used."
        )
        exit()

    if folder_id == "folders/<your_folder_id>":
        print("ERROR: The folder id must be set before the cli can be used.")
        exit()


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

    check_config()

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
