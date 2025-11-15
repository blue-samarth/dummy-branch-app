from flask import Blueprint, jsonify
from sqlalchemy import text
import time

from ..db import SessionContext
from ..logging import setup_request_context, log

bp = Blueprint("health", __name__)

@bp.before_request
def before_request():
    setup_request_context()

@bp.route("/health", methods=["GET"])
def health():
    log("Health check")
    return jsonify({"status": "ok"})

@bp.route("/health-db", methods=["GET"])
def health_db():
    start_time = time.time()
    with SessionContext() as session:
        try:
            session.execute(text("SELECT 1"))
            db_connected = True
        except Exception as e:
            duration = time.time() - start_time
            log("DB health check failed", error=str(e), duration=f"{duration:.4f}s", level="error")
            db_connected = False
    
    duration = time.time() - start_time
    
    if db_connected:
        log("DB health check success", duration=f"{duration:.4f}s")
        return jsonify({"status": f"Connection Successfully Established with the Database in {duration:.4f} seconds"})
    else:
        log("DB health check failed", duration=f"{duration:.4f}s", level="error")
        return jsonify({"status": "Database connection error"}), 500
