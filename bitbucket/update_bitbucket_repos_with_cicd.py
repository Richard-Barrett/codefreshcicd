#!/usr/bin/env python3

import os
import subprocess
import requests

# Bitbucket credentials
api_token = "your_api_token"
workspace = "your_workspace"

# Bitbucket API endpoint
bitbucket_api = f"https://api.bitbucket.org/2.0/repositories/{workspace}"

# Headers for API token authentication
headers = {
    "Authorization": f"Bearer {api_token}"
}

# Directory where repositories will be cloned
clone_dir = "/tmp/bitbucket_repos"

# Content for the Makefile if it's missing
makefile_content = """
.PHONY: all

all:
\t@echo "Running all tasks"
"""

# Get a list of repositories in the workspace
def get_repositories():
    repos = []
    response = requests.get(bitbucket_api, headers=headers)
    if response.status_code == 200:
        data = response.json()
        repos = [repo['slug'] for repo in data['values']]
    return repos

# Clone a repository
def clone_repository(repo_name):
    repo_url = f"https://x-token-auth:{api_token}@bitbucket.org/{workspace}/{repo_name}.git"
    repo_path = os.path.join(clone_dir, repo_name)
    if not os.path.exists(repo_path):
        subprocess.run(["git", "clone", repo_url, repo_path])
    return repo_path

# Check if a file exists, and add it if missing
def check_and_add_file(repo_path, filename, contents):
    file_path = os.path.join(repo_path, filename)
    if not os.path.exists(file_path):
        with open(file_path, "w") as file:
            file.write(contents)
        return True
    return False

# Generate the content dynamically based on repo name
def generate_file_contents(repo_name):
    precommit_content = f"# {repo_name} precommit configuration\n"
    tagging_content = f"# {repo_name} tagging configuration\n"
    pre_commit_config = "# Pre-commit configuration file\n"

    return precommit_content, tagging_content, pre_commit_config

# Check and add missing YAML files and Makefile
def check_and_add_files(repo_path, repo_name):
    precommit_content, tagging_content, pre_commit_config = generate_file_contents(repo_name)

    added_files = False
    # Add <repo_name>-precommit.yaml
    if check_and_add_file(repo_path, f"{repo_name}-precommit.yaml", precommit_content):
        print(f"Added {repo_name}-precommit.yaml")
        added_files = True

    # Add <repo_name>-tagging.yaml
    if check_and_add_file(repo_path, f"{repo_name}-tagging.yaml", tagging_content):
        print(f"Added {repo_name}-tagging.yaml")
        added_files = True

    # Add .pre-commit-config.yaml
    if check_and_add_file(repo_path, ".pre-commit-config.yaml", pre_commit_config):
        print(f"Added .pre-commit-config.yaml")
        added_files = True

    # Add Makefile if missing
    if check_and_add_file(repo_path, "Makefile", makefile_content):
        print(f"Added Makefile")
        added_files = True

    return added_files

# Commit and push changes to the repository
def commit_and_push_changes(repo_path):
    subprocess.run(["git", "add", "."], cwd=repo_path)
    subprocess.run(["git", "commit", "-m", "Add missing YAML files and Makefile"], cwd=repo_path)
    subprocess.run(["git", "push"], cwd=repo_path)

# Main function to process all repositories
def process_repositories():
    os.makedirs(clone_dir, exist_ok=True)
    repos = get_repositories()
    for repo in repos:
        print(f"Processing repository: {repo}")
        repo_path = clone_repository(repo)
        if check_and_add_files(repo_path, repo):
            commit_and_push_changes(repo_path)
        else:
            print(f"No files added for {repo}. Skipping commit and push.")
    print("All repositories processed.")

if __name__ == "__main__":
    process_repositories()
