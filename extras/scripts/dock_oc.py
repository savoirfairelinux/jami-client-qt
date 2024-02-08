#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# dock_oc.py -- Docker Operation Commands - a helper script for building,
# running, and executing Jami-client build commands in a Docker container.
# "with great power comes great responsibility" - Uncle Ben
# i.e. this script contains commands that may need to be kept up-to-date
#
# Note: As a developer, you should be able to run this script from the
# root of the Jami client source tree, but make sure either have a clean
# build or use a separate repository for the running of this script that
# has initialized submodules.
#
# Example usage to build the client and run tests:
# ./extras/scripts/dock_oc.py --workspace /path/to/jami-client-qt all

# Copyright (C) 2024 Savoir-faire Linux Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301 USA.

import subprocess
import argparse
import os

# Default constants
DEFAULT_IMAGE_TAG = "jami-client-build"
DEFAULT_DOCKERFILE = "extras/build/docker/Dockerfile.client-qt-gnulinux"
DEFAULT_WORKSPACE = os.getcwd()
DEFAULT_CACHE = "/var/cache/jami"

# Compute default user-id
DEFAULT_USER_ID = os.getuid()

# Use the host's CPU count
CPU_COUNT = os.cpu_count() or 4  # Defaults to 4 if os.cpu_count() is None

class DockerManager:
    """Manages Docker operations for building, running, and executing commands in containers."""

    def __init__(self, image_tag, user_id, workspace, cache, dockerfile):
        self.image_tag = image_tag
        self.user_id = user_id
        self.workspace = workspace
        self.cache = cache
        self.dockerfile = dockerfile

    def image_exists(self):
        """Checks if the Docker image already exists."""
        result = subprocess.run(["docker", "images", "-q", self.image_tag], capture_output=True, text=True)
        return result.stdout.strip() != ""

    def build_image(self):
        """Builds Docker image without cache using the specified Dockerfile if it doesn't already exist."""
        if not self.image_exists():
            print(f"-------------- Building image {self.image_tag}...")
            subprocess.run([
                "docker", "build", "-t", self.image_tag,
                "-f", self.dockerfile, "--no-cache", "."
            ], check=True)
        else:
            print(f"Image {self.image_tag} already exists. Skipping build.")

    def run_container(self, interactive=False):
        """Runs Docker container in detached mode and returns the container ID."""
        print("-------------- Running container...")
        cmd = ["docker", "run"]
        if interactive:
            cmd.extend(["-it", "--rm"])
        else:
            cmd.extend(["-d", "-t"])
        cmd.extend([
            "-u", f"{self.user_id}:{self.user_id}",
            "-v", f"{self.workspace}:/foo:rw",
            "-v", f"{self.cache}:/var/cache/jami:rw",
            "-w", "/foo", "-e", "BATCH_MODE=1", self.image_tag, "/bin/bash"
        ])
        if interactive:
            subprocess.run(cmd)
            exit(0)
        result = subprocess.run(cmd, capture_output=True, text=True)
        # Check if the container was successfully run. If not it's likely a path issue.
        # Warn the user about using relative paths for the workspace and cache.
        container_id = result.stdout.strip()
        if result.returncode != 0 or container_id == "":
            print("Failed to run container. Check the workspace and cache paths.")
            print("Make sure to use absolute paths for the workspace and cache.")
            exit(1)
        print(f"Container ID: {container_id}")
        return container_id

    def exec_commands(self, container_id, commands):
        """Executes a series of commands inside the specified container."""
        for command in commands:
            print(f"-------------- Executing command: {command}")
            try:
                subprocess.run(["docker", "exec", "-t", container_id, "sh", "-c", command], check=True)
            except subprocess.CalledProcessError as e:
                print(f"Error executing command: {e}")

    def clean_build_directory(self):
        """Removes the build directory inside the Docker container."""
        clean_command = "rm -rf /foo/build"
        try:
            subprocess.run([
                "docker", "exec", "-t", self.run_container(), "sh", "-c", clean_command
                ], check=True)
            print("Build directory cleaned.")
        except subprocess.CalledProcessError as e:
            print(f"Failed to clean build directory: {e}")

    def remove_image(self):
        """Removes the Docker image."""
        try:
            subprocess.run(["docker", "rmi", self.image_tag], check=True)
            print(f"Image {self.image_tag} removed successfully.")
        except subprocess.CalledProcessError as e:
            print(f"Failed to remove image {self.image_tag}: {e}")

def setup_argparse():
    """Sets up command-line argument parsing with subcommands and Dockerfile path."""
    parser = argparse.ArgumentParser(description="Docker Operations Manager")
    parser.add_argument("--image-tag", default=DEFAULT_IMAGE_TAG, help="Tag for the Docker image.")
    parser.add_argument("--user-id", default=DEFAULT_USER_ID, help="User ID for the container.", type=int)
    parser.add_argument("--workspace", default=DEFAULT_WORKSPACE, help="Host workspace path.")
    parser.add_argument("--cache", default=DEFAULT_CACHE, help="Cache directory path.")
    parser.add_argument("--dockerfile", default=DEFAULT_DOCKERFILE, help="Path to the Dockerfile.")

    # Subcommands
    subparsers = parser.add_subparsers(dest="command", required=True, help="Subcommands")
    subparsers.add_parser("contrib", help="Execute contrib commands only")
    client_parser = subparsers.add_parser("client", help="Execute client build commands only")
    client_parser.add_argument("--skip-tests", action="store_true", help="Skip test compilation and execution.")
    all_parser = subparsers.add_parser("all", help="Execute all commands")
    all_parser.add_argument("--skip-tests", action="store_true", help="Skip test compilation and execution for client.")
    subparsers.add_parser("interactive", help="Get an interactive shell in the container")
    subparsers.add_parser("clean", help="Clean the build directory")
    subparsers.add_parser("remove", help="Remove the built Docker image")

    return parser.parse_args()

def get_commands(args):
    """Determines the set of commands to execute based on the arguments and subcommands."""
    docker_top_dir = "/foo"  # Assuming this is your project's top directory in the Docker container

    contrib_commands = [
        ("cd /foo/daemon/contrib && mkdir -p native && cd native && "
         "../bootstrap --cache-dir=/var/cache/jami --cache-builds && "
         "make list && make fetch")
    ]

    client_commands = [
        f"cd /foo/ && ./build.py --install --qt /usr/lib/libqt-jami/"
        f" --extra-cmake-flags='-DENABLE_TESTS=True'" if not args.skip_tests else ""
    ]

    test_commands = []
    if not args.skip_tests:
        test_commands = [
            f"cd {docker_top_dir}/build/tests && HOME=/tmp ctest -V -C Release -j{CPU_COUNT}"
        ]

    if args.command == "contrib":
        return contrib_commands
    elif args.command == "client":
        return client_commands + (test_commands if not args.skip_tests else [])
    elif args.command == "all":
        return contrib_commands + client_commands + (test_commands if not args.skip_tests else [])


if __name__ == "__main__":
    args = setup_argparse()

    manager = DockerManager(args.image_tag, str(args.user_id), args.workspace, args.cache, args.dockerfile)
    manager.build_image()

    if args.command == "interactive":
        if not manager.image_exists():
            manager.build_image()
        print("Starting an interactive shell...")
        container_id = manager.run_container(interactive=True)
    elif args.command == "clean":
        if not manager.image_exists():
            print("Image does not exist, nothing to clean.")
        else:
            container_id = manager.run_container()
            manager.clean_build_directory()
    elif args.command == "remove":
        manager.remove_image()
    else:
        container_id = manager.run_container()
        commands = get_commands(args)
        manager.exec_commands(container_id, commands)
        print(f"Operations completed in container {container_id}")
