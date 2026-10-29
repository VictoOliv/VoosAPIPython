"""Testes do contrato GET da API com HTML controlado, sem acessar o FlightAware."""

import unittest
from unittest.mock import patch

import requests

from app import app


HTML = """
<table class="airportBoard">
<tr><th>Arrivals</th></tr>
<tr><td>GLO1234</td><td>B738</td><td>Brasília</td><td>10:00</td><td></td><td>11:00</td></tr>
</table>
<table class="airportBoard">
<tr><th>Departures</th></tr>
<tr><td>AZU4321</td><td>A320</td><td>Recife</td><td>12:00</td><td></td><td>14:00</td></tr>
</table>
"""


class FlightApiTests(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()

    def test_index(self):
        response = self.client.get("/api")
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.json["endpoints"])

    def test_rejects_invalid_filters_before_scraping(self):
        with patch("services.flightaware.requests.get") as fetch:
            for query in ("aeroporto=123", "tipo=invalido"):
                response = self.client.get("/api/voos?" + query)
                self.assertEqual(response.status_code, 400)
                self.assertIn("erro", response.json)
            fetch.assert_not_called()

    def test_scraping_filters_and_cors(self):
        upstream = requests.Response()
        upstream.status_code = 200
        upstream._content = HTML.encode("utf-8")
        with patch("services.flightaware.requests.get", return_value=upstream):
            for kind, count in (("chegadas", 1), ("partidas", 1), ("todos", 2)):
                with self.subTest(kind=kind):
                    response = self.client.get(
                        "/api/voos?aeroporto=sbgr&tipo=" + kind,
                        headers={"Origin": "http://localhost:8101"},
                    )
                    self.assertEqual(response.status_code, 200)
                    self.assertEqual(response.json["aeroporto"], "SBGR")
                    self.assertEqual(response.json["tipo_busca"], kind)
                    self.assertEqual(response.json["total"], count)
                    self.assertEqual(len(response.json["voos"]), count)
                    self.assertEqual(
                        response.headers["Access-Control-Allow-Origin"],
                        "http://localhost:8101",
                    )
                    self.assertEqual(set(response.json["voos"][0]), {
                        "identificacao", "categoria", "local",
                        "tipo_aeronave", "partida", "chegada",
                    })

    def test_upstream_failure_returns_json_error(self):
        with patch("services.flightaware.requests.get", side_effect=requests.Timeout("timeout")):
            response = self.client.get("/api/voos?aeroporto=SBGR")
            self.assertEqual(response.status_code, 502)
            self.assertIn("FlightAware", response.json["erro"])


if __name__ == "__main__":
    unittest.main()

