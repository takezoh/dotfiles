#!/usr/bin/env python3
# coding: utf-8
import os
import shutil
import subprocess


def wpath(path):
    if not os.path.exists(path):
        return None

    path = os.path.realpath(path)
    p = subprocess.run(['wpath', '-aw', path], stdout=subprocess.PIPE, shell=False)
    p.check_returncode()
    return p.stdout.decode('utf-8').rstrip()


def argparse(program, args):
    results = []
    program = shutil.which(program) or program
    program = wpath(program) or program
    for i, value in enumerate(args):
        results.append(wpath(value) or value)
    return program, results
