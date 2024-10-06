<img align="right" width="60" height="60" src="images/codefresh.png">

# Codefresh CICD

A Repository with a collection of CICD Codefresh Scripts  that allows one to make a bunch of Codefresh CICD Pipelines as a callable script

## Getting Started

To get started, first run the following against your `Makefile`, assuming the `Makefile` is in the root of your repository:

```bash
# Prepend content to a Makefile
echo -e '.PHONY: cicd\n\ncicd:\n\tcurl -sS https://raw.githubusercontent.com/Richard-Barrett/codefreshcicd/main/generate_cicd_files.sh | bash\n' | cat - Makefile > temp && mv temp Makefile
```

This will append the following into your `Makefile`:

```bash
.PHONY: cicd

cicd:
    curl -sS https://raw.githubusercontent.com/Richard-Barrett/codefreshcicd/main/generate_cicd_files.sh | bash
```

- The script is already has the following permissions `chmod+x`, which grants it the right to be executable on your system.

## Running the make cicd command

Run the following command in the root of your repository:

```bash
make cicd
```

The script `generate_cicd_files.sh` performs the following actions:
- Dynamically retrieves the repository name.
- Generates three YAML files:
  - `<repo_name>-precommit.yml`: Contains predefined content for pre-commit checks.
  - `<repo_name>-tagging.yml`: Contains predefined content for tagging.
  - `<repo_name>-integration.yml`: Contains custom integration-related content.

The script does not overwrite existing files, so if the YAML files already exist, it will leave them intact.
If you want to see what the `precommit.yml`, `tagging.yml`, and `integration.yml` look like, navigate to the [Codefresh]() directory.
