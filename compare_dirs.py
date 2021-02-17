#!/usr/bin/env python3

import argparse
import glob
import os

parser = argparse.ArgumentParser(description='Compare two directories')
parser.add_argument('original')
parser.add_argument('candidate')

args = parser.parse_args()


old_files = glob.glob(args.original + '**/**', recursive=True)
candidate_files = glob.glob(args.candidate + '**/**', recursive=True)

old_files = [os.path.relpath(f, args.original) for f in old_files]
candidate_files = [os.path.relpath(f, args.candidate) for f in candidate_files]

removed_files = set(old_files) - set(candidate_files)
for f in removed_files:
    print("removed: %s" % f)


new_files = set(candidate_files) - set(old_files)
for f in new_files:
    print("new: %s" % f)

matched_files = set(candidate_files) & set(old_files)

for f in matched_files:
    print("matches: %s" % f)
