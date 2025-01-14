#!/usr/bin/env python3

import os
from flask import Flask, request, jsonify
import json
import argparse
from datetime import datetime
from threading import Thread
from queue import Queue
import time

DEFAULT_MAX_SIZE_MB = 5 * 1024  # 5GB in MB

# Queue for background processing
task_queue = Queue()

def process_background_tasks(max_size_bytes):
    """Background worker that processes queued tasks."""
    while True:
        try:
            task = task_queue.get()
            if task is None:  # Poison pill to stop the worker
                break

            dump_content, metadata, dump_id = task

            # Create directory if needed
            if not os.path.exists(BASE_PATH):
                os.makedirs(BASE_PATH)

            # Calculate sizes
            dump_size = len(dump_content)
            metadata_size = len(json.dumps(metadata, indent=4))

            # Ensure space is available
            ensure_space_available(dump_size + metadata_size, max_size_bytes)

            # Save dump file
            filepath = os.path.join(BASE_PATH, dump_id)
            if not os.path.exists(filepath):
                with open(filepath, 'wb') as f:
                    f.write(dump_content)
                print(f"File saved successfully at {filepath}")

                # Save metadata
                metadata_filepath = os.path.join(BASE_PATH, f"{dump_id}.info")
                with open(metadata_filepath, 'w') as f:
                    f.write(json.dumps(metadata, indent=4))
            else:
                print(f"File {filepath} already exists, skipping")

        except Exception as e:
            print(f"Error in background task: {e}")
        finally:
            task_queue.task_done()

def get_dir_size(path):
    """Calculate total size of a directory in bytes."""
    total_size = 0
    for dirpath, dirnames, filenames in os.walk(path):
        for filename in filenames:
            filepath = os.path.join(dirpath, filename)
            total_size += os.path.getsize(filepath)
    return total_size

def get_oldest_reports(path):
    """Get list of report pairs (dump and info) sorted by creation time."""
    reports = []
    files = os.listdir(path)
    dump_files = [f for f in files if not f.endswith('.info')]

    for dump_file in dump_files:
        info_file = f"{dump_file}.info"
        if info_file in files:
            dump_path = os.path.join(path, dump_file)
            creation_time = os.path.getctime(dump_path)
            reports.append({
                'dump_file': dump_file,
                'info_file': info_file,
                'creation_time': creation_time
            })

    # Sort by creation time (oldest first)
    reports.sort(key=lambda x: x['creation_time'])
    return reports

def ensure_space_available(required_size, max_size_bytes):
    """Ensure there's enough space by removing oldest reports if needed."""
    if not os.path.exists(BASE_PATH):
        return

    current_size = get_dir_size(BASE_PATH)
    if current_size + required_size > max_size_bytes:
        reports = get_oldest_reports(BASE_PATH)
        bytes_to_free = (current_size + required_size) - max_size_bytes
        bytes_freed = 0

        for report in reports:
            if bytes_freed >= bytes_to_free:
                break

            dump_path = os.path.join(BASE_PATH, report['dump_file'])
            info_path = os.path.join(BASE_PATH, report['info_file'])

            # Get sizes before deletion
            dump_size = os.path.getsize(dump_path) if os.path.exists(dump_path) else 0
            info_size = os.path.getsize(info_path) if os.path.exists(info_path) else 0

            # Delete files
            try:
                if os.path.exists(dump_path):
                    os.remove(dump_path)
                if os.path.exists(info_path):
                    os.remove(info_path)
                bytes_freed += dump_size + info_size
                print(f"Removed old report: {report['dump_file']} ({dump_size + info_size} bytes)")
            except OSError as e:
                print(f"Error removing old report: {e}")

def enforce_size_limit(max_size_bytes):
    """Enforce size limit on startup by removing oldest reports if needed."""
    if not os.path.exists(BASE_PATH):
        return

    current_size = get_dir_size(BASE_PATH)
    if current_size > max_size_bytes:
        print(f"Directory size ({current_size} bytes) exceeds limit ({max_size_bytes} bytes)")
        print("Removing oldest reports to meet size limit...")
        ensure_space_available(0, max_size_bytes)  # This will remove old files until we're under the limit
        final_size = get_dir_size(BASE_PATH)
        print(f"Final directory size: {final_size} bytes")

app = Flask(__name__)
BASE_PATH = 'crash_reports'

@app.route('/submit', methods=['POST'])
def submit():
    try:
        print("Received a crash report GUID: %s" % request.form.get('guid', 'No GUID provided'))
        file_storage = request.files.get('upload_file_minidump')
        if not file_storage:
            print("No file found for the key 'upload_file_minidump'")
            return 'No file found', 400

        # Read the file content and metadata immediately
        dump_id = file_storage.filename
        dump_content = file_storage.read()
        metadata = dict(request.form)

        # Queue the task for background processing
        task_queue.put((dump_content, metadata, dump_id))

        print("Crash report received; responding with 200")
        return 'Crash report received', 200
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return 'Internal Server Error', 500

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Crash report submission server')
    parser.add_argument('--debug', action='store_true', help='Run in debug mode')
    parser.add_argument('--max-size', type=int, default=DEFAULT_MAX_SIZE_MB,
                       help='Maximum size of the crash report directory in megabytes (default: %(default)s MB)')
    args = parser.parse_args()

    # Convert MB to bytes
    max_size_bytes = args.max_size * 1024 * 1024

    print(f"Starting server with max directory size: {args.max_size} MB ({max_size_bytes:,} bytes)")

    # Start background worker thread with max_size parameter
    background_thread = Thread(target=process_background_tasks, args=(max_size_bytes,), daemon=True)
    background_thread.start()

    # Enforce size limit on startup
    enforce_size_limit(max_size_bytes)

    if args.debug:
        app.run(port=8080, debug=True)
    else:
        from waitress import serve
        print("Starting production server on port 8080...")
        serve(app, host='0.0.0.0', port=8080)

    # Clean shutdown of background thread
    task_queue.put(None)  # Send poison pill
    background_thread.join(timeout=5)  # Wait for thread to finish