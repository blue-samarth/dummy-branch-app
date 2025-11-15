from flask import g, request
from uuid import uuid4
from datetime import datetime, timezone
import json

def setup_request_context():
    """Call this in before_request"""
    g.request_id = request.headers.get('X-Request-ID', str(uuid4()))
    g.start_time = datetime.now((timezone.utc))

def log(message, **kwargs):
    """Simple structured JSON logging"""
    log_data = {
        "timestamp": datetime.now(timezone.utc).isoformat() + "Z",
        "request_id": getattr(g, 'request_id', None),
        "message": message,
        **kwargs
    }
    print(json.dumps(log_data))