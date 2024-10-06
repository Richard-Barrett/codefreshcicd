#!/usr/bin/env python3
import os
import subprocess
import argparse
import requests

# Fetch repositories from BitBucket with custom CNAME
def get_repositories(api_token, workspace, bitbucket_url):
    bitbucket_api = f"{bitbucket_url}/2.0/repositories/{workspace}"
    headers = {"Authorization": f"Bearer {api_token}"}
    response = requests.get(bitbucket_api, headers=headers)
    repos = []

    if response.status_code == 200:
        data = response.json()
        repos = [repo['slug'] for repo in data['values']]
    else:
        print(f"Failed to fetch repositories: {response.status_code} - {response.text}")
    
    return repos

# Clone repository from custom CNAME BitBucket instance
def clone_repository(api_token, workspace, repo_name, clone_dir, bitbucket_url):
    repo_url = f"https://x-token-auth:{api_token}@{bitbucket_url}/{workspace}/{repo_name}.git"
    repo_path = os.path.join(clone_dir, repo_name)

    if not os.path.exists(repo_path):
        subprocess.run(["git", "clone", repo_url, repo_path])
    
    return repo_path

# Check and add file if missing
def check_and_add_file(repo_path, filename, content):
    file_path = os.path.join(repo_path, filename)
    if not os.path.exists(file_path):
        with open(file_path, "w") as file:
            file.write(content)
        return True
    return False

# Add required files to repository
def add_required_files(repo_path, repo_name):
    precommit_content = f"# {repo_name} precommit configuration\n"
    tagging_content = f"# {repo_name} tagging configuration\n"
    pre_commit_config_content = "# Pre-commit configuration file\n"
    makefile_content = """
.PHONY: all

all:
\t@echo "Running all tasks"
"""

    added_files = False
    # Check and add files if they are missing
    if check_and_add_file(repo_path, f"{repo_name}-precommit.yaml", precommit_content):
        print(f"Added {repo_name}-precommit.yaml")
        added_files = True
    
    if check_and_add_file(repo_path, f"{repo_name}-tagging.yaml", tagging_content):
        print(f"Added {repo_name}-tagging.yaml")
        added_files = True

    if check_and_add_file(repo_path, ".pre-commit-config.yaml", pre_commit_config_content):
        print(f"Added .pre-commit-config.yaml")
        added_files = True

    if check_and_add_file(repo_path, "Makefile", makefile_content):
        print(f"Added Makefile")
        added_files = True

    return added_files

# Commit and push changes
def commit_and_push_changes(repo_path):
    subprocess.run(["git", "add", "."], cwd=repo_path)
    subprocess.run(["git", "commit", "-m", "Add missing YAML files and Makefile"], cwd=repo_path)
    subprocess.run(["git", "push"], cwd=repo_path)

# Main function to handle all repository updates
def update_repositories(api_token, workspace, clone_dir, bitbucket_url):
    os.makedirs(clone_dir, exist_ok=True)
    repos = get_repositories(api_token, workspace, bitbucket_url)

    for repo_name in repos:
        print(f"Processing repository: {repo_name}")
        repo_path = clone_repository(api_token, workspace, repo_name, clone_dir, bitbucket_url)
        
        if add_required_files(repo_path, repo_name):
            commit_and_push_changes(repo_path)
        else:
            print(f"No files added for {repo_name}, skipping commit.")

if __name__ == "__main__":
    # Set up argument parsing
    parser = argparse.ArgumentParser(description="Update BitBucket repositories with required YAML files and Makefile.")
    parser.add_argument("--api_token", required=True, help="Your BitBucket API token")
    parser.add_argument("--workspace", required=True, help="Your BitBucket workspace name")
    parser.add_argument("--clone_dir", required=True, help="Directory to clone repositories into")
    parser.add_argument("--bitbucket_url", required=True, help="The custom CNAME URL of your on-prem BitBucket instance (e.g., https://bitbucket.example.com)")

    args = parser.parse_args()

    # Run the repository update process with the custom BitBucket URL
    update_repositories(args.api_token, args.workspace, args.clone_dir, args.bitbucket_url)
