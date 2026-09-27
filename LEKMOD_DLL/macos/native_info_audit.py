"""Conservative Clang-AST mapping of compiled direct scalar cache getters.

This does not establish runtime values or gameplay outcomes.
"""
import json,sqlite3
from pathlib import Path

def roots(path):
 text=path.read_text();decoder=json.JSONDecoder();i=0;result=[]
 while i<len(text):
  while i<len(text)and text[i].isspace():i+=1
  if i==len(text):break
  node,i=decoder.raw_decode(text,i);result.append(node)
 return result

def walk(node):
 yield node
 for child in node.get('inner',[]):yield from walk(child)

def unwrap(n):
 while n.get('kind')in ('ImplicitCastExpr','CStyleCastExpr','CXXStaticCastExpr','ParenExpr')and len(n.get('inner',[]))==1:n=n['inner'][0]
 return n

def mapping(path,table):
 nodes=roots(path);getters={};loads={}
 for root in nodes:
  for method in ([root]+root.get('inner',[])):
   if method.get('kind')!='CXXMethodDecl' or '() const'not in method.get('type',{}).get('qualType',''):continue
   body=next((c for c in method.get('inner',[])if c['kind']=='CompoundStmt'),None)
   if not body:continue
   statements=[c for c in body.get('inner',[])if c['kind']!='NullStmt']
   if len(statements)!=1 or statements[0]['kind']!='ReturnStmt':continue
   ret=unwrap(statements[0]['inner'][0])
   if ret['kind']=='MemberExpr'and ret.get('isArrow')and ret.get('inner',[{}])[0].get('kind')=='CXXThisExpr':
    getters[ret['name']]={'getter':method['name'],'return_type':method['type']['qualType']}
 for root in nodes:
  if root.get('name')!='CacheResults':continue
  for node in walk(root):
   if node.get('kind')!='BinaryOperator'or node.get('opcode')!='=':continue
   left,right=map(unwrap,node['inner'])
   if left['kind']!='MemberExpr'or right['kind']!='CXXMemberCallExpr':continue
   call=right['inner'][0];args=right['inner'][1:]
   if call.get('name')not in ('GetInt','GetBool','GetFloat','GetDouble')or len(args)!=1:continue
   if not any(c.get('referencedDecl',{}).get('name')=='kResults'for c in walk(call)):continue
   arg=unwrap(args[0])
   if arg['kind']!='StringLiteral':continue
   column=json.loads(arg['value']);loads[column]={'member':left['name'],'reader':call['name'],**getters.get(left['name'],{})}
 return loads

