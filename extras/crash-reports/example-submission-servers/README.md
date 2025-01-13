# Crash report submission server examples

## Overview

This directory contains an example of a crash report submission server. This server is responsible for receiving crash reports from clients and storing them. The example is written in Python and uses the Flask web framework with Waitress as the WSGI server. It exposes one endpoint for submitting crash reports on the `/submit` path using the POST method on port `8080`.

It also contains an example of a crash report access server. This server is responsible for displaying the crash reports. It uses port `8081` and provides a simple HTML page that lists crash reports by page.

## Running the examples

To run the examples, you need to have Python 3 installed. You can just use the virtual environment provided in this directory. To activate the virtual environment, run the following commands:

```
python3 -m venv venv
source venv/bin/activate
python3 -m pip install -r requirements.txt
```


> ⚠️ On Windows, you need to use `venv\Scripts\activate` instead of `source venv/bin/activate`.

After activating the virtual environment, you can should be able to execute the example submission server. To run the example submission server that uses the Crashpad format, run the following command:

```
python3 crashpad_submit_server.py
```

To run a server that displays the crash reports, run the following command:

```
python3 report_access_server.py
```

> ⚠️ It is recommended to run the report access server in a way that is not publicly accessible.

Either server can be run on the same machine or on different machines, and each can be run using the `--debug` flag to enable debugging.

## Metadata

The crash report submission servers expect the crash reports to contain a JSON object. The JSON object should contain the following basic metadata:
```
{
    "build_id": "202410021437",
    "client_sha": "77149ebd62",
    "guid": "50c4218a-bcb9-48a9-8093-a06e6435cd61",
    "jamicore_sha": "cbf8f0af6",
    "platform": "Ubuntu 22.04.4 LTS_x86_64"
}
```

The `build_id` field is the build identifier of the client application. The `client_sha` field is the SHA-1 hash of the client application. The `guid` field is a unique identifier for the crash report. The `jamicore_sha` field is the SHA-1 hash of the Jami core library. The `platform` field is the platform on which the client application is running.