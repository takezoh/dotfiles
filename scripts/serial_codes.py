#!/usr/bin/env python
import sys
import uuid
import itertools


def create(num):
    for i in range(int(num)):
        s = uuid.uuid4().hex
        print '{}-{}-{}-{}'.format(s[0:4], s[4:8], s[8:12], s[12:16])


def check(*files):
    print files
    codes = itertools.chain(*[open(f, 'r').readlines() for f in files])
    codes = filter(lambda x: x, map(lambda x: x.strip().replace('-', ''), codes))
    ret = len(codes) == len(set(codes))
    print ret
    sys.exit(not ret)


if __name__ == "__main__":
    func = locals()[sys.argv[1]]
    func(*sys.argv[2:])
