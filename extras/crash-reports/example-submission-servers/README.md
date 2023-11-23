# Crash report submission server examples

## Overview

This directory contains examples of crash report submission servers. These servers are responsible for receiving crash reports from clients and storing them. The examples are written in Python and use the Flask web framework.

## Running the examples

To run the examples, you need to have Python 3 installed. You can just use the virtual environment provided in this directory. To activate the virtual environment, run the following commands:

```
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

After activating the virtual environment, you can should be able to execute the example submission servers. To run the example submission server that uses the Crashpad format, run the following command:

```
python crashpad.py
```

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