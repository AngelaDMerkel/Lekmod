"""Conservative mapping of compiled one-dimensional cache loaders/getters.

This module never declares gameplay coverage. Unrecognized code remains rejected.
"""
import json,re
from native_info_audit import roots,walk,unwrap

LOADERS={'PopulateArrayByValue','PopulateArrayByExistence','SetYields','SetFlavors'}

def literal(node, default=None):
    node=unwrap(node);kind=node.get('kind')
    if kind=='CXXDefaultArgExpr':return default
    if kind in {'IntegerLiteral','CXXBoolLiteralExpr'}:return int(node['value'])
    if kind=='UnaryOperator'and node.get('opcode')=='-'and len(node.get('inner',[]))==1:
        value=literal(node['inner'][0]);return -value if value is not None else None
    return None

def text_literal(node):
    node=unwrap(node)
    return json.loads(node['value'])if node.get('kind')=='StringLiteral'else None

def this_member(node):
    node=unwrap(node)
    if node.get('kind')=='MemberExpr'and node.get('isArrow')and any(c.get('kind')=='CXXThisExpr'for c in node.get('inner',[])):
        return node
    return None

def strip_comments(text):
    pattern=r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|//[^\n]*|/\*.*?\*/'
    return re.sub(pattern,lambda m:' 'if m[0].startswith(('/',))else m[0],text,flags=re.S)

def source_span(node,source):
    try:
        a=node['range']['begin']['offset'];b=node['range']['end'];return source[a:b['offset']+b.get('tokLen',1)].decode()
    except (KeyError,UnicodeDecodeError):return None

def indexed_getter(method,source):
    params=[n for n in method.get('inner',[])if n.get('kind')=='ParmVarDecl']
    body=next((n for n in method.get('inner',[])if n.get('kind')=='CompoundStmt'),None)
    if not body or len(params)!=1 or not method.get('type',{}).get('qualType','').endswith(' const'):return None
    returns=[n for n in walk(body)if n.get('kind')=='ReturnStmt']
    if len(returns)!=1 or len(returns[0].get('inner',[]))!=1:return None
    expr=unwrap(returns[0]['inner'][0]);guard=None;fallback=None
    if expr.get('kind')=='ConditionalOperator':
        cond,yes,no=expr['inner'];guard=this_member(cond);fallback=literal(no)
        if guard is None or fallback is None:return None
        expr=unwrap(yes)
    if expr.get('kind')!='ArraySubscriptExpr':return None
    base,index=map(unwrap,expr['inner']);member=this_member(base)
    if member is None or index.get('referencedDecl',{}).get('id')!=params[0].get('id'):return None
    if guard is not None and guard.get('referencedMemberDecl')!=member.get('referencedMemberDecl'):return None
    body_text=source_span(body,source);return_text=source_span(returns[0],source)
    if not body_text or not return_text or not body_text.startswith('{')or not body_text.endswith('}'):return None
    before,sep,after=body_text[1:-1].partition(return_text)
    if not sep or strip_comments(after).strip()not in {'',';'}:return None
    prefix=strip_comments(before)
    if not re.fullmatch(r'(?:\s*CvAssert(?:Msg)?\s*\([^;]*\);\s*)*',prefix)or '++'in prefix or '--'in prefix:return None
    name=re.escape(params[0]['name']);bounds=[]
    for match in re.finditer(r'\b'+name+r'\s*<\s*(GC\.\w+\(\)|NUM_\w+|\d+)',prefix):bounds.append(match[1])
    if not bounds:return None # Every generated access must respect an explicit reviewed bound.
    return dict(member=member['name'],getter=method['name'],return_type=method['type']['qualType'],
                nullable=guard is not None,null_fallback=fallback,bounds=sorted(set(bounds)),parameter_type=params[0].get('type',{}).get('qualType','int'))

def owned_type_variables(cache):
    result=set()
    for node in walk(cache):
        if node.get('kind')!='VarDecl':continue
        calls=[n for n in walk(node)if n.get('kind')=='CXXMemberCallExpr']
        if len(calls)==1:
            fn=unwrap(calls[0]['inner'][0])
            if fn.get('name')=='GetType'and any(n.get('kind')=='CXXThisExpr'for n in walk(fn)):
                result.add(node['id'])
    return result

def array_mapping(ast_path,source):
    nodes=roots(ast_path);getters={};accepted=[];rejected=[]
    for node in nodes:
        for method in [node]+node.get('inner',[]):
            if method.get('kind')=='CXXMethodDecl':
                info=indexed_getter(method,source)
                if info:getters.setdefault(info['member'],[]).append(info)
    for cache in nodes:
        if cache.get('name')!='CacheResults':continue
        body=next((n for n in cache.get('inner',[])if n.get('kind')=='CompoundStmt'),None)
        if not body:continue
        top={id(unwrap(n))for n in body.get('inner',[])};owner_vars=owned_type_variables(cache)
        for node in walk(body):
            if node.get('kind')!='CXXMemberCallExpr':continue
            fn=unwrap(node['inner'][0]);kind=fn.get('name')
            if kind not in LOADERS:continue
            args=node['inner'][1:];member=this_member(args[0]);label=member['name']if member else '?'
            def reject(reason):rejected.append(dict(member=label,loader=kind,reason=reason))
            if id(node)not in top:reject('loader is not an unconditional top-level statement');continue
            if member is None or member.get('type',{}).get('qualType')not in {'int *','bool *'}:reject('unsupported member type');continue
            getter=getters.get(label,[])
            if len(getter)!=1:reject('requires one side-effect-free directly indexed getter with explicit bounds');continue
            later_writes=[]
            end=node.get('range',{}).get('end',{}).get('offset',-1)
            for candidate in walk(body):
                if candidate.get('range',{}).get('begin',{}).get('offset',-1)<=end:continue
                if candidate.get('kind')in {'BinaryOperator','CompoundAssignOperator'} and candidate.get('opcode')in {'=','+=','-=','*=','/='}:
                    if any(n.get('kind')=='MemberExpr'and n.get('name')==label for n in walk(candidate.get('inner',[{}])[0])):later_writes.append(candidate)
                if candidate.get('kind')=='CXXMemberCallExpr':
                    if any(n.get('kind')=='MemberExpr'and n.get('name')==label for arg in candidate.get('inner',[])[1:]for n in walk(arg)):later_writes.append(candidate)
            if later_writes:reject('member has a subsequent write or escapes to another call');continue
            if kind in {'SetYields','SetFlavors'}:
                relation,owner=map(text_literal,args[1:3]);owner_arg=unwrap(args[3])
                axis='Yields'if kind=='SetYields'else'Flavors';key='YieldType'if kind=='SetYields'else'FlavorType';value='Yield'if kind=='SetYields'else'Flavor'
                default=0 if kind=='SetYields'else literal(args[4],0);minimum=0;mode='indexed-value'
            else:
                axis,relation,key,owner=map(text_literal,args[1:5]);owner_arg=unwrap(args[5]);minimum=0
                if kind=='PopulateArrayByValue':
                    value=text_literal(args[6]);default=literal(args[7],0);minimum=literal(args[8],0)
                    if minimum is None:
                        symbol=unwrap(args[8]).get('referencedDecl',{}).get('name')
                        if symbol=='NUM_DOMAIN_TYPES'and axis=='Domains':minimum=symbol
                    mode='indexed-value'
                else:
                    value=None;mode='membership'if member['type']['qualType']=='bool *'else'compact-ids';default=0 if mode=='membership'else -1
            if not all([axis,relation,key,owner])or(mode=='indexed-value'and value is None)or default is None or minimum is None:reject('nonliteral or unreviewed schema/default/size argument');continue
            if owner_arg.get('referencedDecl',{}).get('id')not in owner_vars:reject('filter value is not the current entry GetType()');continue
            accepted.append(dict(member_type=member['type']['qualType'],loader=kind,index_table=axis,relation_table=relation,index_column=key,owner_column=owner,value_column=value,mode=mode,default=default,min_size=minimum,**getter[0]))
    return dict(bindings=accepted,rejected=rejected)
