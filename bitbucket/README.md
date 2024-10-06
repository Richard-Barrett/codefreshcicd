# BitBucket Repositories CI/CD Updater

This Python script, `update_bitbucket_repos_with_cicd.py`, is designed to automatically update all repositories in a specified BitBucket workspace with required YAML configuration files and a Makefile. It works with on-prem BitBucket instances and uses a custom CNAME URL for access.

## Features

- Adds the following files if they are missing:
  - `<repo_name>-precommit.yaml`
  - `<repo_name>-tagging.yaml`
  - `.pre-commit-config.yaml`
  - `Makefile`
- Commits and pushes changes back to the repository.
- Designed for use with on-prem BitBucket servers with custom CNAME URLs.

## Prerequisites

- **Python 3.x**
- **Git**
- **Python `requests` library**: Install using `pip install requests`.
- BitBucket **API Token** with necessary permissions to read, commit, and push to repositories.

## Setup

1. Clone this repository or download `update_bitbucket_repos_with_cicd.py` to your local machine.
2. Ensure you have the required Python libraries:
   ```bash
   pip install requests
   ```
3. Make sure `git` is installed and accessible in your system's PATH.

## Usage

To run the script, open a terminal and execute the following command:

```bash
python3 update_bitbucket_repos_with_cicd.py --api_token YOUR_API_TOKEN --workspace YOUR_WORKSPACE --clone_dir /path/to/clone --bitbucket_url https://bitbucket.example.com
```

### Command-Line Arguments

- `--api_token` (required): Your BitBucket API token for authentication.
- `--workspace` (required): The name of your BitBucket workspace containing the repositories.
- `--clone_dir` (required): The local directory where repositories will be cloned.
- `--bitbucket_url` (required): The custom CNAME URL of your on-prem BitBucket server (e.g., `https://bitbucket.example.com`).

### Example

```bash
python3 update_bitbucket_repos_with_cicd.py --api_token ABC123 --workspace my_workspace --clone_dir /tmp/bitbucket_repos --bitbucket_url https://bitbucket.mycompany.com
```

This will:
1. Fetch all repositories from `my_workspace`.
2. Clone them to `/tmp/bitbucket_repos`.
3. Check each repository for the specified files, adding any that are missing.
4. Commit and push the changes if any files were added.

## Notes

- The script will skip repositories where all specified files are already present.
- Ensure that your BitBucket API token has sufficient permissions to modify the repositories.

## Troubleshooting

- If you encounter errors related to authentication, verify that your API token is correct and has the necessary permissions.
- For errors related to cloning, ensure `git` is installed and accessible.
- Check that the `clone_dir` has sufficient space and permissions for cloning the repositories.

## License

This project is licensed under the MIT License.
