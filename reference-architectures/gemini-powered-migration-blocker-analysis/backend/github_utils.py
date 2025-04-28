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
#

import asyncio
import git 
import os
import tempfile 
import shutil
from pathlib import Path
from typing import Dict, Optional, List
from git.exc import GitCommandError 

# TODO : Make this a more robust implementation, allowing for IaC files as well
# as k8s manifests

# TODO : Account for directories within a git repo, not just the base repo

# Define common filenames to look for
FILES_TO_EXTRACT = [
    "README.md",
    "README.rst",
    "README.txt",
    "requirements.txt", # Python
    "pyproject.toml",   # Python
    "uv.lock",          # Python
    "package.json",     # Node.js
    "pom.xml",          # Java Maven
    "build.gradle",     # Java/Kotlin Gradle
    "Gemfile",          # Ruby
    "go.mod",           # Go
    "Cargo.toml",       # Rust
    "composer.json",    # PHP
    "Dockerfile",       # Docker
    # Add other relevant files as needed
]

# Max content size to read from each file (to avoid huge prompts)
MAX_FILE_CONTENT_SIZE = 10000 # 10k characters limit per file

async def get_repo_info(repo_url: str) -> Dict[str, Optional[str]]:
    """
    Clones a public Git repository temporarily and extracts content from key files.

    Args:
        repo_url: The HTTPS or SSH URL of the Git repository.

    Returns:
        A dictionary where keys are standardized names (e.g., 'readme',
        'requirements_txt') and values are the file contents (str) or None if
        not found or error reading. Returns an empty dict if cloning fails.
    """
    extracted_info: Dict[str, Optional[str]] = {
        "readme": None,
        "dependencies": None, # Combine multiple dependency files here? Or separate keys? Let's combine for now.
        "dockerfile": None,
        # Add keys for other specific files if needed
    }
    # Use a temporary directory that gets automatically cleaned up
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)
        print(f"Attempting to clone repository '{repo_url}' into '{temp_path}'...")

        try:
            # Run the blocking Git clone operation in a thread pool executor
            loop = asyncio.get_running_loop()
            await loop.run_in_executor(
                None, # Default executor
                lambda: git.Repo.clone_from(
                    repo_url,
                    temp_path,
                    depth=1 # Shallow clone (faster, less disk space)
                )
            )
            print(f"Successfully cloned repository: {repo_url}")

            # --- Find and read key files ---
            dependency_contents = []
            for filename in FILES_TO_EXTRACT:
                file_path = temp_path / filename
                if file_path.is_file():
                    print(f"Found file: {filename}")
                    try:
                        content = file_path.read_text(encoding='utf-8', errors='ignore')
                        # Truncate if too long
                        if len(content) > MAX_FILE_CONTENT_SIZE:
                            print(f"Truncating content of {filename} from {len(content)} chars.")
                            content = content[:MAX_FILE_CONTENT_SIZE] + "\n... [TRUNCATED]"

                        # Categorize the content
                        if filename.lower().startswith("readme"):
                            if extracted_info["readme"] is None: # Take the first README found
                                extracted_info["readme"] = content
                        elif filename == "Dockerfile":
                             extracted_info["dockerfile"] = content
                        else: # Assume other files are dependency related
                             dependency_contents.append(f"--- Content of {filename} ---\n{content}")

                    except Exception as read_err:
                        print(f"Warning: Could not read file {filename}: {read_err}")

            if dependency_contents:
                extracted_info["dependencies"] = "\n\n".join(dependency_contents)

        except GitCommandError as git_err:
            print(f"Error cloning repository {repo_url}: {git_err}")
            # Return specific error info? For now, just return empty dict effectively
            # Could raise a custom exception here
            return {"error": f"Failed to clone repository: {git_err}"}
        except Exception as e:
            print(f"An unexpected error occurred during repository processing: {e}")
            return {"error": f"Unexpected error processing repository: {e}"}

    print(f"Finished processing repository. Readme found: {extracted_info['readme'] is not None}. Dependencies found: {extracted_info['dependencies'] is not None}")
    return extracted_info