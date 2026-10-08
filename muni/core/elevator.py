#!/usr/bin/env python3
from __future__ import annotations
import argparse,json,os,platform,subprocess,sys,time
from pathlib import Path
VERSION="0.3.1"
EXCLUDE={".git","node_modules",".venv","venv","__pycache__","target","build",".lake"}
EXT={".py":"python",".pyi":"python",".ts":"node",".tsx":"node",".js":"node",".jsx":"node",".rs":"rust",".go":"go",".c":"c",".h":"c",".cc":"c",".cpp":"c",".hpp":"c",".java":"java",".lean":"lean",".jl":"julia"}
def run(cmd,cwd,timeout):
 t=time.time()
 try:
  p=subprocess.run(cmd,cwd=cwd,text=True,capture_output=True,timeout=timeout)
  return {"command":cmd,"returncode":p.returncode,"seconds":time.time()-t,"stdout":p.stdout[-12000:],"stderr":p.stderr[-12000:]}
 except Exception as e:
  return {"command":cmd,"returncode":-1,"seconds":time.time()-t,"stdout":"","stderr":repr(e)}
def inventory(root):
 found=[]; sources=0
 markers={"python":("pyproject.toml","setup.py","requirements.txt"),"node":("package.json",),"rust":("Cargo.toml",),"go":("go.mod",),"c":("CMakeLists.txt","Makefile"),"java":("pom.xml","build.gradle","build.gradle.kts"),"lean":("lakefile.toml","lakefile.lean","lean-toolchain"),"julia":("Project.toml",)}
 for base,dirs,files in os.walk(root):
  dirs[:]=[d for d in dirs if d not in EXCLUDE and not d.startswith(".")]
  for f in files:
   lang=EXT.get(Path(f).suffix)
   if lang: sources+=1; found.append(lang)
 for lang,names in markers.items():
  if any((root/n).exists() for n in names): found.append(lang)
 return {"languages":sorted(set(found)),"source_files":sources}
def adapters(root,langs):
 out=[]
 if "python" in langs: out.append(("python","python-test",[sys.executable,"-m","pytest","-q"]))
 if "node" in langs: out.append(("node","node-test",["npm","test","--","--runInBand"]))
 if "rust" in langs: out.append(("rust","rust-test",["cargo","test"]))
 if "go" in langs: out.append(("go","go-test",["go","test","./..."]))
 if "c" in langs: out.append(("c","cmake-build",["cmake","--build","build"]) if (root/"CMakeLists.txt").exists() else ("c","make-plan",["make","-n"]))
 if "java" in langs: out.append(("java","maven-test",["./mvnw","test"] if (root/"mvnw").exists() else ["mvn","test"]))
 if "lean" in langs: out.append(("lean","lean-build",["lake","build"]))
 if "julia" in langs: out.append(("julia","julia-test",["julia","--project=.","-e","using Pkg; Pkg.test()"]))
 return out
def main():
 ap=argparse.ArgumentParser(prog="muni-core"); ap.add_argument("command",choices=("inspect","elevate")); ap.add_argument("target",nargs="?",default="."); ap.add_argument("--execute",action="store_true"); ap.add_argument("--timeout",type=int,default=120); ap.add_argument("--out")
 a=ap.parse_args(); root=Path(a.target).resolve()
 if not root.is_dir(): raise SystemExit("MUNI_ERROR target is not a directory")
 inv=inventory(root); ads=adapters(root,inv["languages"]); primary=ads[0] if ads else None
 ev={"schema":"muni.elevation.v1","engine_version":VERSION,"target":str(root),"timestamp_unix":time.time(),"host":{"machine":platform.machine(),"system":platform.system(),"release":platform.release()},"inventory":inv,"available_adapters":[{"language":x[0],"name":x[1],"command":x[2]} for x in ads],"adapter":primary[1] if primary else None,"detected_command":primary[2] if primary else None,"gap_candidates":[{"kind":"PROFILE_REQUIRED","language":x,"status":"CANDIDATE"} for x in inv["languages"]],"gates":{"inventory":True,"baseline":False,"formal_gap":False,"certificate":False,"transformation":False,"semantic_validation":False,"adversarial":False,"native_measurement":False,"claim":"CANDIDATE"}}
 if a.execute and primary:
  ev["baseline"]=run(primary[2],root,a.timeout); ev["gates"]["baseline"]=ev["baseline"]["returncode"]==0
  ev["gates"]["claim"]="FORMAL_PARTIAL" if ev["gates"]["baseline"] else "CANDIDATE"
 elif a.execute: ev["baseline"]={"status":"NO_ADAPTER"}
 ev["next_action"]="Provide a formal gap certificate and transformation plugin before optimization."
 if a.command=="inspect": print(json.dumps(ev,indent=2)); return 0
 out=Path(a.out).resolve() if a.out else root/"AGD_ELEVATION_RECEIPT.json"
 out.write_text(json.dumps(ev,indent=2)+"\n")
 print(json.dumps({"status":ev["gates"]["claim"],"receipt":str(out),"adapter":ev["adapter"],"execute":a.execute},indent=2))
if __name__=="__main__": raise SystemExit(main())
