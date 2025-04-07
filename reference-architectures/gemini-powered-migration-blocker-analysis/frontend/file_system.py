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
from os import getcwd, listdir
from os.path import isfile, join
from typing import List


logger = logging.getLogger(__name__)


def list_files_in_directory(directory_path: str) -> List[str]:
    """
    Lists all files (not directories) directly within the specified directory.

    Handles common errors like the directory not existing, not being a directory,
    or permission issues by printing an informative error message and returning
    an empty list.

    Args:
        directory_path: The path to the directory to scan.

    Returns:
        A list of filenames within the directory. Returns an empty list if
        the directory is empty, does not exist, is not accessible,
        or if any other error occurs during listing.
    """
    logger.debug("Current working directory: %s", getcwd())
    # Check if the input is actually a string
    if not isinstance(directory_path, str):
        logger.error(
            "Error: Input 'directory_path' must be a string, but got %s",
            type(directory_path),
        )
        return []
    logger.debug("Loading file list from %s", directory_path)
    try:
        files = [
            join(directory_path, f)
            for f in listdir(directory_path)
            if isfile(join(directory_path, f))
        ]
        logger.debug("Got file list in %s: %s", directory_path, files)
        return files
    except FileNotFoundError:
        logger.error("Error: Directory not found at path: %s", directory_path)
        # Return an empty list on error
        return []
    except NotADirectoryError:
        logger.error("Error: The path %s is a file, not a directory.", directory_path)
        return []
    except PermissionError:
        print("Error: Permission denied to access directory: %s", directory_path)
        return []
