#!/usr/bin/env python3
import json
import sys
import tomllib
from pathlib import Path


def load_data(path: str, fmt: str):
	p = Path(path)
	if not p.exists():
		return {}
	if fmt == 'json':
		return json.loads(p.read_text())
	if fmt == 'toml':
		with p.open('rb') as f:
			return tomllib.load(f)
		raise SystemExit(f'unsupported format: {fmt}')


def merge(existing, managed):
	"""Shallow merge: managed wins at top level, extra existing keys are kept."""
	if isinstance(existing, dict) and isinstance(managed, dict):
		return {**existing, **managed}
	return managed if managed is not None else existing


def quote_key(key: str) -> str:
	if any(c in key for c in ' \t/\\@.'):
		return f'"{key}"'
	return key


def write_toml(data, prefix=''):
	scalars = [(k, v) for k, v in data.items() if not isinstance(v, dict)]
	tables = [(k, v) for k, v in data.items() if isinstance(v, dict)]
	lines = []
	for k, v in scalars:
		if isinstance(v, bool):
			lines.append(f'{quote_key(k)} = {"true" if v else "false"}')
		elif isinstance(v, str):
			lines.append(f'{quote_key(k)} = {v!r}')
		elif isinstance(v, (int, float)):
			lines.append(f'{quote_key(k)} = {v}')
		elif isinstance(v, list):
			items = ', '.join(repr(i) if isinstance(i, str) else str(i) for i in v)
			lines.append(f'{quote_key(k)} = [{items}]')
	for k, v in tables:
		header = f'{prefix}.{quote_key(k)}' if prefix else quote_key(k)
		lines.append(f'\n[{header}]')
		lines.extend(write_toml(v, header))
	return lines


def dump_data(data, fmt: str):
	if fmt == 'json':
		json.dump(data, sys.stdout, ensure_ascii=False, indent=2)
		sys.stdout.write('\n')
		return
	if fmt == 'toml':
		sys.stdout.write('\n'.join(write_toml(data)).lstrip('\n') + '\n')
		return
	raise SystemExit(f'unsupported format: {fmt}')


def main():
	if len(sys.argv) != 4:
		raise SystemExit('usage: merge_append.py <json|toml> <managed> <existing>')
	fmt, managed_path, existing_path = sys.argv[1:4]
	managed = load_data(managed_path, fmt)
	existing = load_data(existing_path, fmt)
	dump_data(merge(existing, managed), fmt)


if __name__ == '__main__':
	main()
