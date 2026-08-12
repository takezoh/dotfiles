#!/usr/bin/python3
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ARTIFACT = Path(__file__).with_name("artifacts") / "xai-route-disposition.json"


class XaiDispositionTests(unittest.TestCase):
	def test_revision_matched_oauth_proof_retires_only_xai(self):
		artifact = json.loads(ARTIFACT.read_text())
		self.assertEqual(artifact["proof_revision"], "53e0ae7a447b58e3470e8a1816616864ffb26f65")
		self.assertEqual(artifact["classification"], "retired")
		self.assertFalse(artifact["installed_other_consumers"])
		config = (ROOT / "assets/config.toml").read_text()
		self.assertNotIn('path = "/grok-x-search"', config)
		self.assertIn('name = "ctx-sync"', config)


if __name__ == "__main__": unittest.main()
