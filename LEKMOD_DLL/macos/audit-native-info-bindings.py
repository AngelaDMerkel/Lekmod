#!/usr/bin/env python3
"""Inspect active compiled scalar getter bindings using exact native build flags."""
from pathlib import Path
import json,subprocess,hashlib,concurrent.futures
from native_info_audit import mapping
import argparse
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output-dir',type=Path,required=True);p.add_argument('--discovery',type=Path,required=True);a=p.parse_args()
root=Path(__file__).resolve().parents[2];out=a.output_dir.resolve();out.mkdir(parents=True,exist_ok=True);src=root/'LEKMOD_DLL/CvGameCoreDLL_Expansion2'
classes={'Buildings':'CvBuildingEntry','Units':'CvUnitEntry','UnitPromotions':'CvPromotionEntry','Traits':'CvTraitEntry','Policies':'CvPolicyEntry','Beliefs':'CvBeliefEntry','Improvements':'CvImprovementEntry','Technologies':'CvTechEntry','Projects':'CvProjectEntry','Specialists':'CvSpecialistInfo','HandicapInfos':'CvHandicapInfo','GameSpeeds':'CvGameSpeedInfo','Eras':'CvEraInfo','Leaders':'CvLeaderHeadInfo','Worlds':'CvWorldInfo','Terrains':'CvTerrainInfo','Features':'CvFeatureInfo','Resources':'CvResourceInfo','Builds':'CvBuildInfo','Routes':'CvRouteInfo','GoodyHuts':'CvGoodyInfo','GameOptions':'CvGameOptionInfo','Civilizations':'CvCivilizationInfo','PolicyBranchTypes':'CvPolicyBranchEntry'}
files={p:p.read_text(errors='replace')for p in src.glob('*.cpp')}
flags=json.loads((root/'build/macos/build-report.json').read_text())['flags']
discovery=json.loads(a.discovery.read_text())
def one(item):
 table,klass=item;matches=[p for p,text in files.items()if klass+'::CacheResults('in text]
 if len(matches)!=1:return {'table':table,'error':'source lookup '+str(len(matches))}
 source=matches[0];ast=out/(klass+'.ast.json');log=out/(klass+'.ast.log')
 if True:
  with ast.open('w')as f,log.open('w')as err:
   result=subprocess.run(['clang++',*flags,'-fsyntax-only','-Xclang','-ast-dump=json','-Xclang','-ast-dump-filter='+klass,str(source)],stdout=f,stderr=err)
  if result.returncode:return {'table':table,'error':'compiler failed; '+str(log)}
 fields={c['column']for c in discovery['candidates']if c.get('table')==table and c['kind']=='scalar-field'}
 bindings=mapping(ast,table);mapped={k:v for k,v in bindings.items()if k in fields and 'getter'in v}
 result={'table':table,'class':klass,'source':str(source.relative_to(root)),'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'bindings':mapped,'unmapped':sorted(fields-set(mapped)),'configured_fields':len(fields)}
 (out/(table+'-bindings.json')).write_text(json.dumps(result,indent=2)+'\n');return result
with concurrent.futures.ThreadPoolExecutor(max_workers=4)as pool:results=list(pool.map(one,classes.items()))
summary={'scope':'Compiled-source direct getter mapping only; no native runtime or gameplay pass.','rows':results,'mapped_fields':sum(len(r.get('bindings',{}))for r in results),'configured_fields':sum(r.get('configured_fields',0)for r in results)}
(out/'compiled-bindings.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps({'mapped_fields':summary['mapped_fields'],'configured_fields':summary['configured_fields'],'tables':[(r['table'],len(r.get('bindings',{})),r.get('configured_fields'),r.get('error'))for r in results]},indent=2))
