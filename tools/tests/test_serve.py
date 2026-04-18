import http.server

from tools.serve import COOP_COEP_Handler


def test_handler_inheritance():
    assert issubclass(COOP_COEP_Handler, http.server.SimpleHTTPRequestHandler)
