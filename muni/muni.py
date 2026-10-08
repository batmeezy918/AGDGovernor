#!/usr/bin/env python3
import argparse,json,os,subprocess,sys
ROOT=os.path.dirname(os.path.abspath(__file__))
def selftest():
 p=os.path.join(ROOT,'tests','test_callable_ctypes.py')
 return subprocess.run([sys.executable,p],cwd=os.path.dirname(p)).returncode
def receipt():
 for n in ('agd_callable.receipt.json','agd_persistent_runtime.receipt.json'):
  p=os.path.join(ROOT,'receipts',n)
  if os.path.exists(p): print(open(p).read())
def elevate(path):
 print(json.dumps({'status':'CANDIDATE','target':os.path.abspath(path),'pipeline':['inventory','baseline','profile','formal_gap','certificate','transform','native_validate','adversarial','silicon_measure','claim'],'policy':'refuse uncertified transformations'},indent=2))
p=argparse.ArgumentParser(prog='muni'); s=p.add_subparsers(dest='cmd',required=True)
s.add_parser('self-test'); s.add_parser('receipt'); e=s.add_parser('elevate'); e.add_argument('repository')
a=p.parse_args()
if a.cmd=='self-test': raise SystemExit(selftest())
if a.cmd=='receipt': receipt()
if a.cmd=='elevate': elevate(a.repository)
