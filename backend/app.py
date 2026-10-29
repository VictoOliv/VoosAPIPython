import os

from flask import Flask, jsonify
from flask_cors import CORS

from controllers import historico_api_bp, voos_api_bp
from models import db


ENDPOINTS = [
    {
        "metodo": "GET",
        "rota": "/api/voos",
        "descricao": "Webscraping ao vivo no FlightAware",
        "query": "?aeroporto=SBGR&tipo=chegadas|partidas|todos",
    },
    {
        "metodo": "POST",
        "rota": "/api/voos/sincronizar",
        "descricao": "Scraping + grava coleta",
        "query": "?aeroporto=SBGR&tipo=chegadas|partidas|todos",
    },
    {
        "metodo": "GET",
        "rota": "/api/historico/coletas",
        "descricao": "Lista coletas gravadas",
    },
    {
        "metodo": "GET",
        "rota": "/api/historico/coletas/<id>",
        "descricao": "Detalhe de uma coleta",
    },
]


def criar_app():
    app = Flask(__name__)

    # Permite que o Flutter Web acesse a API
    CORS(app)

    pasta = os.path.abspath(
        os.path.dirname(__file__)
    )

    app.config["SQLALCHEMY_DATABASE_URI"] = (
        "sqlite:///"
        + os.path.join(
            pasta,
            "principal.db",
        )
    )

    app.config["SQLALCHEMY_BINDS"] = {
        "historico": (
            "sqlite:///"
            + os.path.join(
                pasta,
                "historico_voos.db",
            )
        )
    }

    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

    db.init_app(app)

    # Somente APIs.
    app.register_blueprint(
        voos_api_bp
    )

    app.register_blueprint(
        historico_api_bp
    )

    with app.app_context():
        db.create_all()

    @app.route("/api")
    def api_index():
        return jsonify(
            {
                "aula": "Aula 19 - Webscraping de voos",
                "endpoints": ENDPOINTS,
            }
        )

    return app


app = criar_app()


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=5001,
        debug=True,
    )