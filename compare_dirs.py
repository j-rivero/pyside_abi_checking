#!/usr/bin/env python3

import argparse
import difflib
import glob
import os
import subprocess

parser = argparse.ArgumentParser(description='Compare two directories')
parser.add_argument('original')
parser.add_argument('candidate')

args = parser.parse_args()


old_files = glob.glob(args.original + '**/**', recursive=True)
candidate_files = glob.glob(args.candidate + '**/**', recursive=True)

# remove directories from analysis and broken symlinks
old_files = [f for f in old_files if not os.path.isdir(f) or not os.path.exists(f)]
candidate_files = [f for f in candidate_files if not os.path.isdir(f) or not os.path.exists(f)]

old_files = [os.path.relpath(f, args.original) for f in old_files]
candidate_files = [os.path.relpath(f, args.candidate) for f in candidate_files]

ignored_endings = ('changelog.Debian.gz', 'copyright')

old_files = [f for f in old_files if not f.endswith(ignored_endings)]
candidate_files = [f for f in candidate_files if not f.endswith(ignored_endings)]


removed_files = set(old_files) - set(candidate_files)
for f in removed_files:
    print("removed: %s" % f)


new_files = set(candidate_files) - set(old_files)
for f in new_files:
    print("new: %s" % f)

matched_files = set(candidate_files) & set(old_files)

matched_headers = []
matched_libraries = []
matched_other = []
for f in matched_files:
    if f.endswith(('.h', '.xml', '.cmake', '.py', '.pc')):
        matched_headers.append(f)
    elif f.endswith('.so'):
        matched_libraries.append(f)
    else:
        matched_other.append(f)

def diff_files(local_filename, root1, root2, library=False):
    fn1 = os.path.join(root1, local_filename)
    fn2 = os.path.join(root2, local_filename)
    f1 = None
    f2 = None
    if library:
        cmd = ['nm', '-gD', fn1]
        # print("running command %s" % cmd)
        try:
            f1 = subprocess.check_output(cmd).decode().splitlines(keepends=True)
        except subprocess.CalledProcessError as ex:
            print("ERROR cmd %s failed with error %s" % (cmd, ex))
        cmd = ['nm', '-gD', fn2]
        try:
            f2 = subprocess.check_output(cmd).decode().splitlines(keepends=True)
        except subprocess.CalledProcessError as ex:
            print("ERROR cmd %s failed with error %s" % (cmd, ex))
    else:
        with open(fn1, 'r') as fh:
            f1 = fh.readlines()
        with open(fn2, 'r') as fh:
            f2 = fh.readlines()
    if f1 and f2:
        udiff = difflib.unified_diff(f1, f2, fromfile=fn1, tofile=fn2)
        return ''.join(udiff)
    return 'Error processing %s ' % local_filename

for f in matched_headers:
    print("matched headers: %s" % f)
    diff = diff_files(f, args.original, args.candidate)
    if diff:
        print('diff is:')
        print(diff)
    else:
        print('no diff')

for f in matched_libraries:
    print("matched libs: %s" % f)
    diff = diff_files(f, args.original, args.candidate, library=True)
    if diff:
        print("diff is:")
        print(diff)
    else:
        print("no diff")

for f in matched_other:
    print("matched other: %s" % f)