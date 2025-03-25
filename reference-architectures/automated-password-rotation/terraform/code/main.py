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

import base64
import time
import json
import os
import urllib.request
import string
import random
import sqlalchemy
from sqlalchemy.sql import text
from sqlalchemy.sql.expression import bindparam
from google.cloud.sql.connector import Connector, IPTypes
from google.cloud import secretmanager
from cloudevents.http import CloudEvent
import functions_framework


@functions_framework.cloud_event
def password_rotation_function(cloud_event: CloudEvent):
    """Background Cloud Function to be triggered by Pub/Sub.
    Args:
         cloud_event (CloudEvent):  Event of type google.cloud.pubsub.topic.v1.messagePublished
    """
    pubsub_message = base64.b64decode(cloud_event.data["message"]["data"]).decode()
    message_data = json.loads(pubsub_message)
    project_id = get_project_id()
    secret_id = message_data["secretid"]
    db_user = message_data["db_user"]
    db_name = message_data["db_name"]
    location = message_data["db_location"]
    instance_name = message_data["instance_name"]
    client = secretmanager.SecretManagerServiceClient()
    # Get and rotate the secret
    parent = f"projects/{project_id}/secrets/{secret_id}"
    response = client.access_secret_version(
        request={"name": f"{parent}/versions/latest"}
    )
    db_pass = response.payload.data.decode("UTF-8")
    new_db_pass = get_random_string(10)
    reset_password_status = reset_password(
        instance_name, db_name, location, db_user, db_pass, new_db_pass
    )
    if reset_password_status:
        print("DB password changed successfully")
    else:
        print("Unable to change password")
        return reset_password_status
    verify = verify_change_password(
        instance_name, db_name, location, db_user, new_db_pass
    )
    if verify:
        print("DB password verified successfully")
    else:
        print("Unable to verify password.")

    print("Now updating the password in secret manager")
    update_secret_status = update_secret(project_id, secret_id, new_db_pass)
    if update_secret_status:
        print(f"Secret {secret_id} rotated successfully!")
    else:
        print(f"Unable to update {secret_id}")
        return update_secret


def get_project_id():
    """Function to fetch project id.
    Args:
        None.
    Returns:
        project_id: Id of the project
    """
    url = "http://metadata.google.internal/computeMetadata/v1/project/project-id"
    req = urllib.request.Request(url)
    req.add_header("Metadata-Flavor", "Google")
    project_id = urllib.request.urlopen(req).read().decode()
    return project_id


def get_random_string(length):
    """Function to generate random string.
    Args:
        length: Length of the string to generate
    Returns:
        result_str: Random string
    """
    # choose from all lowercase letter
    letters = string.ascii_lowercase
    result_str = "".join(random.choice(letters) for i in range(length))
    return result_str


def update_secret(project_id, secret_id, new_secret_value):
    """Updates the value of a secret in Google Cloud Secret Manager.
    Args:
        project_id (str): Your Google Cloud Project ID.
        secret_id (str): The ID of the secret to update.
        new_secret_value (bytes): The new secret value as a bytes object.
    """
    client = secretmanager.SecretManagerServiceClient()

    # Build the secret path (required format for Secret Manager)
    name = f"projects/{project_id}/secrets/{secret_id}"

    # Prepare the payload with the updated secret data
    payload = {"data": new_secret_value.encode("UTF-8")}

    response = client.access_secret_version(request={"name": name + "/versions/latest"})
    # Perform the update
    try:
        updated_secret = client.add_secret_version(
            request={
                "parent": name,
                "payload": payload,
            }
        )
        print(f"Updated secret {secret_id} to version: {updated_secret.name}")
        return True
    except Exception as e:
        print(e)
        return False


# Function to establish a database connection
def getconn(instance_connection_name, user, password, db):
    """Function to establish connection with CloudSQl.
    Args:
         instance_connection_name(string) : instance connection name
         user (string)                    : postgressql user
         password(string)                 : user password
         db(string.                       : database
    Returns:
        conn : connection
    """
    with Connector(ip_type=IPTypes.PRIVATE) as connector:
        conn = connector.connect(
            instance_connection_name,
            "pg8000",
            user=user,
            password=password,
            db=db,
        )
        return conn


def reset_password(instance_name, db_name, location, db_user, db_pass, new_db_pass):
    """Function to reset Postgresql user password.
    Args:
         instance_name(string)  : Cloudsql instance name
         db_name(string)        : postgres db user
         location(string)       : Cloudsql instance location
         db_user(string)        : posygres db user
         db_pass(string)        : postgres db password
         new_db_pass(string)    : new password
    Returns:
         True/False(bool)       : flag indicating success or failure in restting the password
    """
    project_id = get_project_id()
    instance_connection_name = project_id + ":" + location + ":" + instance_name

    # Establish the connection pool
    def conn():
        return getconn(instance_connection_name, db_user, db_pass, db_name)

    try:
        pool = sqlalchemy.create_engine(
            "postgresql+pg8000://",
            creator=conn,
        )
    except Exception as e:
        print(e)

    try:
        with pool.connect() as db_conn:
            query = f"ALTER USER {db_user} WITH PASSWORD '{new_db_pass}'"
            db_conn.execute(text(query))
            db_conn.commit()
            print("Password reset successfully!")
        pool.dispose()
        time.sleep(10)
        return True
    except Exception as e:
        print("Failed to reset password due to the following exception")
        print(e)
        return False


def verify_change_password(instance_name, db_name, location, db_user, db_pass):
    """Function to test Postgresql user password.
    Args:
         instance_name(string)  : Cloudsql instance name
         db_name(string)        : postgres db user
         location(string)       : Cloudsql instance location
         db_user(string)        : posygres db user
         db_pass(string)        : postgres db password
    Returns:
         True/False(bool)       : flag indicating success or failure in verifying the password
    """
    project_id = get_project_id()
    instance_connection_name = project_id + ":" + location + ":" + instance_name

    # Establish the connection pool
    def conn_verify():
        return getconn(instance_connection_name, db_user, db_pass, db_name)

    pool = sqlalchemy.create_engine(
        "postgresql+pg8000://",
        creator=conn_verify,
    )
    print("Verifying the new password works by executing a sample query")
    try:
        with pool.connect() as db_conn:
            results = db_conn.execute(
                sqlalchemy.text("select * from information_schema.tables limit 1;")
            ).fetchall()
            for row in results:
                print(row)
        return True
    except Exception as e:
        print("Cannot verify that the new password due to the following exception")
        print(e)
        return False
