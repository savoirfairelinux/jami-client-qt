#!/usr/bin/env python3

import os
from flask import Flask, request, jsonify
import json
import argparse

app = Flask(__name__)
BASE_PATH = 'crash_reports'

@app.route('/submit', methods=['POST'])
def submit():
    try:
        print("Received a crash report GUID: %s" % request.form.get('guid', 'No GUID provided'))
        file_storage = request.files.get('upload_file_minidump')
        dump_id = ""
        if file_storage:
            dump_id = file_storage.filename

            # Create a directory to store the crash reports if it doesn't exist
            if not os.path.exists(BASE_PATH):
                os.makedirs(BASE_PATH)

            filepath = os.path.join(BASE_PATH, dump_id)

            # Attempt to write the file, fail gracefully if it already exists
            if os.path.exists(filepath):
                print(f"File {filepath} already exists.")
                return 'File already exists', 409
            with open(filepath, 'wb') as f:
                f.write(file_storage.read())
            print(f"File saved successfully at {filepath}")

            # Now save the metadata in {request.form} as separate filename <UID>.info.
            metadata_filepath = os.path.join(BASE_PATH, f"{dump_id}.info")
            with open(metadata_filepath, 'w') as f:
                f.write(str(json.dumps(dict(request.form), indent=4)))
        else:
            print("No file found for the key 'upload_file_minidump'")
            return 'No file found', 400

        return 'Crash report received', 200
    except OSError as e:
        print(f"Error creating directory or writing file: {e}")
        return 'Internal Server Error', 500
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return 'Internal Server Error', 500

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Crash report submission server')
    parser.add_argument('--debug', action='store_true', help='Run in debug mode')
    args = parser.parse_args()

    if args.debug:
        app.run(port=8080, debug=True)
    else:
        from waitress import serve
        print("Starting production server on port 8080...")
        serve(app, host='0.0.0.0', port=8080)