#!/usr/bin/env python3

import os
from flask import Flask, request, jsonify, render_template_string, send_file
import json
from datetime import datetime
import argparse

app = Flask(__name__)
BASE_PATH = 'crash_reports'

@app.route('/', methods=['GET'])
def list_reports():
    try:
        if not os.path.exists(BASE_PATH):
            return jsonify({"error": "No reports directory found"}), 404

        # Get page number from query parameters, default to 1
        page = int(request.args.get('page', 1))
        per_page = 10

        reports = os.listdir(BASE_PATH)
        if not reports:
            return render_template_string("""
                <h1>Crash Reports</h1>
                <p>No crash reports found.</p>
            """)

        # Build report pairs with metadata
        report_pairs = []
        for report in reports:
            if not report.endswith('.info'):
                info_file = f"{report}.info"
                if info_file in reports:
                    try:
                        dump_path = os.path.join(BASE_PATH, report)
                        timestamp = os.path.getctime(dump_path)
                        upload_time = datetime.fromtimestamp(timestamp)

                        with open(os.path.join(BASE_PATH, info_file), 'r') as f:
                            metadata = json.load(f)
                            report_pairs.append({
                                'dump_file': report,
                                'info_file': info_file,
                                'metadata': metadata,
                                'sort_key': f"{metadata.get('client_sha', '')}-{metadata.get('jamicore_sha', '')}",
                                'download_name': f"{metadata.get('client_sha', 'unknown')}-{metadata.get('jamicore_sha', 'unknown')}-{metadata.get('platform', 'unknown').replace(' ', '_')}",
                                'upload_time': upload_time
                            })
                    except json.JSONDecodeError:
                        print(f"Error parsing metadata file: {info_file}")
                        continue

        # Sort reports by upload time (most recent first), then by SHA
        report_pairs.sort(key=lambda x: (-x['upload_time'].timestamp(), x['sort_key']))

        # Calculate pagination values
        total_reports = len(report_pairs)
        total_pages = (total_reports + per_page - 1) // per_page
        page = min(max(1, page), total_pages or 1)  # Handle case when total_pages is 0
        start_idx = (page - 1) * per_page
        end_idx = start_idx + per_page

        # Get current page's reports
        current_page_reports = report_pairs[start_idx:end_idx]

        return render_template_string("""
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <title>Crash Reports</title>
                <style>
                    body { font-family: Arial, sans-serif; margin: 2em; }
                    .header {
                        margin-bottom: 2em;
                    }
                    .header h1 {
                        margin-bottom: 0.5em;
                    }
                    .report-list { list-style: none; padding: 0; }
                    .report-item { margin: 1em 0; padding: 1em; border: 1px solid #ddd; border-radius: 4px; }
                    .download-link {
                        display: inline-block;
                        padding: 8px 16px;
                        background-color: #0066cc;
                        color: white;
                        text-decoration: none;
                        border-radius: 4px;
                        margin: 8px 0;
                    }
                    .download-link:hover { background-color: #0052a3; }
                    .metadata-table {
                        border-collapse: collapse;
                        width: 100%;
                        margin: 8px 0;
                    }
                    .metadata-table td {
                        padding: 4px 8px;
                        border-bottom: 1px solid #ddd;
                    }
                    .metadata-table td:first-child {
                        font-weight: bold;
                        width: 150px;
                    }
                    .upload-time {
                        color: #666;
                        font-size: 0.9em;
                        margin-bottom: 8px;
                    }
                    .pagination {
                        margin: 1em 0;
                        text-align: center;
                    }
                    .pagination a, .pagination span {
                        display: inline-block;
                        padding: 8px 16px;
                        margin: 0 4px;
                        border: 1px solid #ddd;
                        border-radius: 4px;
                        text-decoration: none;
                        color: #0066cc;
                    }
                    .pagination .current {
                        background-color: #0066cc;
                        color: white;
                        border-color: #0066cc;
                    }
                    .pagination a:hover {
                        background-color: #f5f5f5;
                    }
                    .pagination-info {
                        text-align: center;
                        color: #666;
                        margin-bottom: 10px;
                    }
                </style>
            </head>
            <body>
                <div class="header">
                    <h1>Crash Reports</h1>
                    <div class="pagination-info">
                        Showing {{ start_idx + 1 }}-{{ [end_idx, total_reports] | min }} of {{ total_reports }} reports
                    </div>
                    <div class="pagination">
                        {% if page > 1 %}
                            <a href="{{ url_for('list_reports', page=1) }}">&laquo; First</a>
                            <a href="{{ url_for('list_reports', page=page-1) }}">&lsaquo; Previous</a>
                        {% endif %}

                        {% for p in range([1, page-2] | max, [total_pages + 1, page + 3] | min) %}
                            {% if p == page %}
                                <span class="current">{{ p }}</span>
                            {% else %}
                                <a href="{{ url_for('list_reports', page=p) }}">{{ p }}</a>
                            {% endif %}
                        {% endfor %}

                        {% if page < total_pages %}
                            <a href="{{ url_for('list_reports', page=page+1) }}">Next &rsaquo;</a>
                            <a href="{{ url_for('list_reports', page=total_pages) }}">Last &raquo;</a>
                        {% endif %}
                    </div>
                </div>

                <div class="report-list">
                {% for report in reports %}
                    <div class="report-item">
                        <h3>Report: {{ report['sort_key'] }}</h3>
                        <div class="upload-time">
                            Uploaded: {{ report['upload_time'].strftime('%Y-%m-%d %H:%M:%S') }}
                        </div>
                        <table class="metadata-table">
                            <tr>
                                <td>Platform:</td>
                                <td>{{ report['metadata']['platform'] }}</td>
                            </tr>
                            <tr>
                                <td>Client SHA:</td>
                                <td>{{ report['metadata']['client_sha'] }}</td>
                            </tr>
                            <tr>
                                <td>Jami Core SHA:</td>
                                <td>{{ report['metadata']['jamicore_sha'] }}</td>
                            </tr>
                            <tr>
                                <td>Build ID:</td>
                                <td>{{ report['metadata']['build_id'] }}</td>
                            </tr>
                            <tr>
                                <td>GUID:</td>
                                <td>{{ report['metadata']['guid'] }}</td>
                            </tr>
                        </table>
                        <a class="download-link" href="{{ url_for('download_report_bundle', dump_file=report['dump_file'], info_file=report['info_file'], download_name=report['download_name']) }}">
                            Download Report Bundle
                        </a>
                    </div>
                {% endfor %}
                </div>
            </body>
            </html>
        """, reports=current_page_reports, page=page, total_pages=total_pages,
             start_idx=start_idx, end_idx=end_idx, total_reports=total_reports)

    except Exception as e:
        print(f"Error listing reports: {e}")
        return 'Internal Server Error', 500

@app.route('/download-bundle/<path:dump_file>/<path:info_file>/<path:download_name>')
def download_report_bundle(dump_file, info_file, download_name):
    try:
        import zipfile
        from io import BytesIO

        # Create a memory file for the zip
        memory_file = BytesIO()

        # Create the zip file
        with zipfile.ZipFile(memory_file, 'w', zipfile.ZIP_DEFLATED) as zf:
            # Add the dump file
            dump_path = os.path.join(BASE_PATH, dump_file)
            zf.write(dump_path, f"{download_name}.dmp")

            # Add the info file
            info_path = os.path.join(BASE_PATH, info_file)
            zf.write(info_path, f"{download_name}.info")

        # Seek to the beginning of the memory file
        memory_file.seek(0)

        return send_file(
            memory_file,
            mimetype='application/zip',
            as_attachment=True,
            download_name=f"{download_name}.zip"
        )
    except Exception as e:
        print(f"Error creating zip bundle: {e}")
        return 'Internal Server Error', 500

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Crash reports viewing server')
    parser.add_argument('--debug', action='store_true', help='Run in debug mode')
    args = parser.parse_args()

    if args.debug:
        app.run(port=8081, debug=True)
    else:
        from waitress import serve
        print("Starting production server on port 8081...")
        serve(app, host='0.0.0.0', port=8081)