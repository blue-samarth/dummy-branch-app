from flask import Flask
from prometheus_flask_exporter import PrometheusMetrics

from .config import Config

def create_app() -> Flask:
    app = Flask(__name__)
    app.config.from_object(Config())

    init_metrics(app)

    # Lazy imports to avoid circular deps during app init
    from .routes.health import bp as health_bp
    from .routes.loans import bp as loans_bp
    from .routes.stats import bp as stats_bp

    app.register_blueprint(health_bp)
    app.register_blueprint(loans_bp, url_prefix="/api")
    app.register_blueprint(stats_bp, url_prefix="/api")

    return app


def init_metrics(app: Flask):
    metrics = PrometheusMetrics(app)
    metrics.info('app_info', 'Application info', version='1.0.0')
    return metrics