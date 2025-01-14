# Crash Report Server Examples

## Overview

This directory contains two servers:
1. A crash report submission server that receives and stores crash reports (port 8080)
2. A crash report access server that provides a web interface to view reports (port 8081)

Both servers are written in Python using Flask with Waitress as the WSGI server.

## Setup Options

### Using Docker (Recommended)

#### Prerequisites
- Docker
- Docker Compose

#### Configuration

1. Create a `.env` file with your configuration:
```
# Directory for crash reports storage (host path)
CRASH_REPORTS_DIR="C:/Users/your_user/path/to/crash_reports"

# Server ports
SUBMIT_SERVER_PORT=8080
REPORTS_SERVER_PORT=8081

# Maximum size for reports directory in MB
MAX_REPORTS_SIZE_MB=5120  # 5GB
```

2. Optionally create the crash reports directory on your host machine:
```powershell
# Windows (PowerShell)
New-Item -ItemType Directory -Force -Path "C:\Users\your_user\path\to\crash_reports"

# Linux/WSL
mkdir -p /path/to/crash_reports
```

Note: When using WSL with Docker Desktop, use Windows-style paths (C:/Users/...) in the `.env` file.

#### Running the Services

Start both servers and follow their logs:
```bash
docker-compose up -d && docker-compose logs -f
```

The `-d` flag runs the services in detached mode (background), and `logs -f` follows the log output.

#### Managing Services

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f                    # Follow all logs
docker-compose logs -f submit            # Follow submit server logs
docker-compose logs -f reports           # Follow reports server logs
docker-compose logs -f --tail=100        # Show last 100 lines and follow

# Stop services
docker-compose down

# Rebuild (after code changes)
docker-compose build && docker-compose up -d
```

### Local Development Setup

1. Create a Python virtual environment:
```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
python3 -m pip install -r requirements.txt
```

2. Run the servers (in separate terminals):
```bash
python3 crashpad_submit_server.py --debug
python3 report_access_server.py --debug
```

## Accessing the Services

- Submit Server: http://localhost:8080/submit (POST endpoint)
- Reports Interface: http://localhost:8081

## Crash Report Metadata

The submission server expects crash reports to contain a JSON object with the following metadata:
```json
{
    "build_id": "202410021437",
    "client_sha": "77149ebd62",
    "guid": "50c4218a-bcb9-48a9-8093-a06e6435cd61",
    "jamicore_sha": "cbf8f0af6",
    "platform": "Ubuntu 22.04.4 LTS_x86_64"
}
```

Fields:
- `build_id`: Build identifier of the client application
- `client_sha`: SHA-1 hash of the client application
- `guid`: Unique identifier for the crash report
- `jamicore_sha`: SHA-1 hash of the Jami core library
- `platform`: Platform identifier

## Directory Management

The crash reports directory:
- Is mounted into both containers when using Docker
- Will be created automatically if it doesn't exist
- Is limited to the size specified in `MAX_REPORTS_SIZE_MB`
- Automatically prunes oldest reports when the size limit is reached

> ⚠️ It is recommended to run the report access server in a way that is not publicly accessible.