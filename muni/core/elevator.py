#!/usr/bin/env python3
"""MUNI general elevation engine."""
from __future__ import annotations
import argparse, hashlib, json, os, platform, subprocess, sys, time
from pathlib import Path
VERSION="0.3.0"
def run(cmd,cwd,timeout=60):
    t=time.time()
    try:
        p=subprocess.run(cmd,cwd=cwd,text=True,capture_output=True,timeout=timeout)
        return {"command":cmd,"returncode":p.returncode,"seconds":time.time()-t,"stdout":p.stdout[-12000:],"stderr":p.stderr[-12000:]}
    except Exception as e:
        return {"command":cmd,"returncode":-1,"seconds":time.time()-t,"stdout":"","stderr":repr(e)}
def inventory(root):
    patterns={"python":("pyproject.toml","setup.py","requirements.txt"),"node":("package.json",),"rust":("Cargo.toml",),"go":("go.mod",),"c":("CMakeLists.txt","Makefile"),"java":("pom.xml","build.gradle","build.gradle.kts"),"lean":("lakefile.toml","lakefile.lean","lean-toolchain"),"julia":("Project.toml",)}
    found=[]; sources=0; ex={'.git','node_modules','.venv','venv','__pycache__','target','build','.lake'}
    ext={'.py':'python','.pyi':'python','.ts':'node','.tsx':'node','.js':'node','.jsx':'node','.rs':'rust','.go':'go','.c':'c','.h':'c','.cc':'c','.cpp':'c','.hpp':'c','.java':'java','.lean':'lean','.jl':'julia'}
    for base,dirs,files in os.walk(root):
        dirs[:]=[d for d in dirs if d not in ex and not d.startswith('.')]
        for f in files:
            if Path(f).suffix in ext: sources+=1; found.append(ext[Path(f).suffix])
    for lang,names in patterns.items():
        if any((root/n).exists() for n in names): found.append(lang)
    return {"languages":sorted(set(found)),"source_files":sources}
def adapter(root,langs):
    if "python" in langs: return ([sys.executable,"-m","pytest","-q"],"python-test")
    if "node" in langs: return (["npm","test","--","--runInBand"],"node-test")
    if "rust" in langs: return (["cargo","test"],"rust-test")
    if "go" in langs: return (["go","test","./..."],"go-test")
    if "c" in langs:
        return ((["cmake","--build","build"],"cmake-build") if (root/"CMakeLists.txt").exists() else (["make","-n"],"make-plan"))
    if "java" in langs: return ((["./mvnw","test"],"maven-test") if (root/"mvnw").exists() else (["mvn","test"],"maven-test"))
    if "lean" in langs: return (["lake","build"],"lean-build")
    if "julia" in langs: return (["julia","--project=.","-e","using Pkg; Pkg.test()"],"julia-test")
    return None,None
def main():
    ap=argparse.ArgumentParser(prog="muni-core"); ap.add_argument("command",choices=("elevate","inspect")); ap.add_argument("target",nargs="?",default="."); ap.add_argument("--execute",action="store_true"); ap.add_argument("--timeout",type=int,default=120); ap.add_argument("--out")
    a=ap.parse_args(); root=Path(a.target).resolve()
    if not root.is_dir(): raise SystemExit("MUNI_ERROR target is not a directory")
    inv=inventory(root); cmd,adapter_name=adapter(root,inv["languages"])
    gaps=[]
    for lang in inv["languages"]: gaps.append({"kind":"PROFILE_REQUIRED","language":lang,"status":"CANDIDATE","reason":"Execution/profile evidence is required before transformation."})
    ev={"schema":"muni.elevation.v1","engine_version":VERSION,"target":str(root),"timestamp_unix":time.time(),"host":{"machine":platform.machine(),"system":platform.system(),"release":platform.release()},"inventory":inv,"adapter":adapter_name,"detected_command":cmd,"gap_candidates":gaps,"gates":{"inventory":True,"baseline":False,"formal_gap":False,"certificate":False,"transformation":False,"semantic_validation":False,"adversarial":False,"native_measurement":False,"claim":"CANDIDATE"}}
    if a.execute and cmd:
        ev["baseline"]=run(cmd,root,a.timeout); ev["gates"]["baseline"]=ev["baseline"]["returncode"]==0
        ev["gates"]["claim"]="FORMAL_PARTIAL" if ev["gates"]["baseline"] else "CANDIDATE"
    elif a.execute: ev["baseline"]={"status":"NO_ADAPTER"}
    ev["next_action"]="Attach a formal gap certificate and transformation plugin before optimization."
    if a.command=="inspect": print(json.dumps(ev,indent=2)); return 0
    out=Path(a.out).resolve() if a.out else root/"AGD_ELEVATION_RECEIPT.json"; out.write_text(json.dumps(ev,indent=2)+"
")
    print(json.dumps({"status":ev["gates"]["claim"],"receipt":str(out),"adapter":adapter_name,"execute":a.execute},indent=2))
if __name__=="__main__": raise SystemExit(main())
