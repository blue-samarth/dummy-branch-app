from flask import Blueprint, jsonify
from ..db import SessionContext
import logging
import time
from sqlalchemy import text

bp = Blueprint("health", __name__)

@bp.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"})

@bp.route("/health-db", methods=["GET"])
def health_db():
    start_time: float = time.time()
    with SessionContext() as session:
        try:
            session.execute(text("SELECT 1"))
            db_connected = True
        except Exception as e:
            logging.error(f"DB health check failed: {e}")
            db_connected = False
    end_time: float = time.time()
    duration: float = end_time - start_time
    if db_connected:
        return jsonify({"status": f"Connection Successfully Established with the Database in {duration:.4f} seconds"})
    else:
        return jsonify({"status": "Database connection error"}), 500