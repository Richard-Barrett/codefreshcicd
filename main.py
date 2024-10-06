#!/usr/bin/env python3

import argparse
import subprocess
import os

def run_update_script(api_token, workspace, clone_dir):
    # Path to the secondary script
    script_path = os.path.join("bitbucket", "update_bitbucket_repos_with_cicd.py")
    
    # Construct the command to call the update script with the provided arguments
    command = [
        "python3", script_path,
        "--api_token", api_token,
        "--workspace", workspace,
        "--clone_dir", clone_dir
    ]
    
    # Run the command and capture the output
    result = subprocess.run(command, capture_output=True, text=True)
    
    # Print the output and any errors from the update script
    if result.stdout:
        print("Output:\n", result.stdout)
    if result.stderr:
        print("Errors:\n", result.stderr)
    
    # Check if the script encountered any errors
    if result.returncode != 0:
        print("An error occurred while running the update script.")
    else:
        print("Update script ran successfully.")

if __name__ == "__main__":
    # Set up argument parser
    parser = argparse.ArgumentParser(description="Run the BitBucket update script with specified CLI arguments.")
    
    # Add required arguments
    parser.add_argument("--api_token", required=True, help="Your BitBucket API token")
    parser.add_argument("--workspace", required=True, help="Your BitBucket workspace name")
    
    # Add optional argument for clone directory
    parser.add_argument("--clone_dir", default="/tmp/bitbucket_repos", help="Directory to clone repositories into")
    
    # Parse the arguments
    args = parser.parse_args()
    
    # Call the update script with the provided arguments
    run_update_script(args.api_token, args.workspace, args.clone_dir)
