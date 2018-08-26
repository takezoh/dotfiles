# -*- coding: utf-8 -*-
import sys

def calc_width(x):
    #  return 2 if len(x.encode('utf-8')) > 1 else 1
    return 2 if len(x) > 1 else 1

if __name__ == "__main__":
    #  context = sys.stdin.read().decode('utf-8')
    context = sys.stdin.read()
    # print sum(map(calc_width, context)) - 1
    print(sum(map(calc_width, context)) - 0)
