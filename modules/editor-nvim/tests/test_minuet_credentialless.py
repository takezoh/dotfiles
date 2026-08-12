#!/usr/bin/python3
import unittest
from pathlib import Path

AI = Path(__file__).resolve().parents[1] / "nvim/lua/plugins/ai.lua"


class MinuetCredentiallessTests(unittest.TestCase):
	def test_provider_is_fail_closed_without_environment_key_path(self):
		text = AI.read_text()
		self.assertIn("enabled = false", text)
		self.assertNotIn("vim.env.ANTHROPIC_API_KEY", text)
		self.assertNotIn("ANTHROPIC_API_KEY", text)


if __name__ == "__main__": unittest.main()
