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
    image: python:3.10  # Or use a different base image if needed
    stage: "PreCommit Check"
    commands:
      # Install Terraform
      - wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
      - unzip terraform_1.5.0_linux_amd64.zip
      - mv terraform /usr/local/bin/

      # Install TFLint
      - curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

      # Install Terraform Docs
      - wget https://github.com/terraform-docs/terraform-docs/releases/download/v0.16.0/terraform-docs-v0.16.0-linux-amd64.tar.gz
      - tar -xvzf terraform-docs-v0.16.0-linux-amd64.tar.gz
      - mv terraform-docs /usr/local/bin/

      # Install pre-commit
      - python -m pip install --upgrade pip
      - pip install pre-commit

      # Disable strict host key checking
      - echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config

      # Verify installations
      - terraform --version
      - tflint --version
      - terraform-docs --version
      - pre-commit --version

      # Run pre-commit hooks
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

# Create the YAML files
echo "$precommit_content" > "${repo_name}-precommit.yml"
echo "$tagging_content" > "${repo_name}-tagging.yml"
echo "$integration_content" > "${repo_name}-integration.yml"

echo "YAML files created successfully:"
echo "${repo_name}-precommit.yml"
echo "${repo_name}-tagging.yml"
echo "${repo_name}-integration.yml"
