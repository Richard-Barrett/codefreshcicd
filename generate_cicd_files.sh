#!/bin/bash

# Get the repository name (assuming this is a Git repo)
repo_name=$(basename "$(git rev-parse --show-toplevel)")

# Predefined contents for precommit.yml
precommit_content='---
version: "1.0"
stages:
  - "PreCommit Check"

steps:
  clone_repo:
    title: "Clone Repository"
    type: "git-clone"
    repo: "${{CF_REPO_OWNER}}/${{CF_REPO_NAME}}"
    revision: "${{CF_BRANCH_TAG_NORMALIZED}}"
    stage: "PreCommit Check"

  install_and_run_all:
    title: "Install Tools and Run Pre-Commit Hooks"
    image: python:3.10
    stage: "PreCommit Check"
    commands:
      - wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
      - unzip terraform_1.5.0_linux_amd64.zip
      - mv terraform /usr/local/bin/
      - curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
      - wget https://github.com/terraform-docs/terraform-docs/releases/download/v0.16.0/terraform-docs-v0.16.0-linux-amd64.tar.gz
      - tar -xvzf terraform-docs-v0.16.0-linux-amd64.tar.gz
      - mv terraform-docs /usr/local/bin/
      - python -m pip install --upgrade pip
      - pip install pre-commit
      - echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config
      - terraform --version
      - tflint --version
      - terraform-docs --version
      - pre-commit --version
      - cd ${{CF_VOLUME_PATH}}/${{CF_REPO_NAME}}
      - pre-commit run --all-files
'

# Predefined contents for tagging.yml
tagging_content='---
version: "1.0"
stages:
  - "clone"
  - "bump_version"
  - "push_tag"

steps:
  clone_repo:
    title: "Cloning repository"
    type: "git-clone"
    repo: "${{CF_REPO_NAME}}"
    revision: "${{CF_BRANCH}}"
    stage: "clone"
  
  detect_last_tag:
    title: "Detecting last tag"
    type: "freestyle"
    image: "alpine/git"
    stage: "bump_version"
    commands:
      - LAST_TAG=$(git describe --tags --abbrev=0 || echo "0.0.0")
      - echo "Last tag detected: $LAST_TAG"
      - echo "LAST_TAG=$LAST_TAG" >> $CF_VOLUME_PATH/env_vars_to_export
    volumes:
      - name: env_vars_to_export
        path: /codefresh/volume/env_vars_to_export
  
  determine_new_version:
    title: "Determining new version"
    type: "freestyle"
    image: "alpine/git"
    stage: "bump_version"
    commands:
      - source $CF_VOLUME_PATH/env_vars_to_export
      - LAST_TAG=$(echo $LAST_TAG)
      - IFS="." read -r -a VERSION <<< "$LAST_TAG"
      - MAJOR=${VERSION[0]}
      - MINOR=${VERSION[1]}
      - PATCH=${VERSION[2]}
      - if echo "$CF_PULL_REQUEST_DESCRIPTION" | grep -q "#major"; then
          MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0;
        elif echo "$CF_PULL_REQUEST_DESCRIPTION" | grep -q "#minor"; then
          MINOR=$((MINOR + 1)); PATCH=0;
        else
          PATCH=$((PATCH + 1));
        fi
      - NEW_TAG="$MAJOR.$MINOR.$PATCH"
      - echo "New tag: $NEW_TAG"
      - echo "NEW_TAG=$NEW_TAG" >> $CF_VOLUME_PATH/env_vars_to_export
    volumes:
      - name: env_vars_to_export
        path: /codefresh/volume/env_vars_to_export
  
  tag_and_push:
    title: "Tagging and pushing to repository"
    type: "freestyle"
    image: "alpine/git"
    stage: "push_tag"
    commands:
      - source $CF_VOLUME_PATH/env_vars_to_export
      - NEW_TAG=$(echo $NEW_TAG)
      - git tag $NEW_TAG
      - git push origin $NEW_TAG
'

# Define custom content for integration.yml
integration_content="# Your custom integration.yml content goes here"

# Define content for .pre-commit-config.yaml
pre_commit_config_content='---
repos:
  - repo: git://github.com/pre-commit/pre-commit-hooks
    rev: v4.0.1
    hooks:
      - id: check-merge-conflict
      - id: check-shebang-scripts-are-executable
      - id: trailing-whitespace
  - repo: https://github.com/gruntwork-io/pre-commit
    rev: v0.1.17
    hooks:
      - id: shellcheck
'

# Function to create a file if it does not exist
create_file_if_missing() {
  local filename="$1"
  local content="$2"
  
  if [[ ! -f "$filename" ]]; then
    echo "$content" > "$filename"
    echo "Created $filename"
  else
    echo "$filename already exists. Skipping..."
  fi
}

# Create the YAML files if they are missing
create_file_if_missing "${repo_name}-precommit.yml" "$precommit_content"
create_file_if_missing "${repo_name}-tagging.yml" "$tagging_content"
create_file_if_missing "${repo_name}-integration.yml" "$integration_content"
create_file_if_missing ".pre-commit-config.yaml" "$pre_commit_config_content"
