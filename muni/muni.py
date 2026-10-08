#!/usr/bin/env python3
import argparse,os,subprocess,sys
ROOT=os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0,os.path.join(ROOT,"core"))
from elevator import main as elevation_main
def selftest():
 p=os.path.join(ROOT,"tests","test_callable_ctypes.py")
 return subprocess.run([sys.executable,p],cwd=os.path.dirname(p)).returncode
def receipt():
 for n in ("agd_callable.receipt.json","agd_persistent_runtime.receipt.json"):
  p=os.path.join(ROOT,"receipts",n)
  if os.path.exists(p): print(open(p).read())
def main():
 p=argparse.ArgumentParser(prog="muni"); s=p.add_subparsers(dest="cmd",required=True)
 s.add_parser("self-test"); s.add_parser("receipt")
 for name in ("elevate","inspect"):
  x=s.add_parser(name); x.add_argument("repository",nargs="?",default="."); x.add_argument("--execute",action="store_true"); x.add_argument("--timeout",type=int,default=120); x.add_argument("--out")
 a=p.parse_args()
 if a.cmd=="self-test": return selftest()
 if a.cmd=="receipt": receipt(); return 0
 old=sys.argv
 try:
  sys.argv=["muni-core",a.cmd,a.repository]
  if a.execute: sys.argv+=["--execute"]
  sys.argv+=["--timeout",str(a.timeout)]
  if a.out: sys.argv+=["--out",a.out]
  return elevation_main()
 finally: sys.argv=old
if __name__=="__main__": raise SystemExit(main())
