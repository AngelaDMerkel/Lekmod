#!/usr/bin/env python3
"""Reject unsafe getter interpretations and preserve distinct loader semantics."""
import copy,json,tempfile,unittest
from pathlib import Path
from native_array_audit import indexed_getter,literal,array_mapping

def node(kind,**kwargs):return dict(kind=kind,**kwargs)
def member(name='m_values'):
    return node('MemberExpr',name=name,isArrow=True,referencedMemberDecl=name,type={'qualType':'int *'},inner=[node('CXXThisExpr')])
class ArrayAuditTests(unittest.TestCase):
    def getter(self,expression=None,prefix='CvAssertMsg(i < GC.getNumResourceInfos(), "bounds");'):
        source=('{'+prefix+'return values;}').encode();start=source.index(b'return');end=source.index(b';',start)
        value=expression or node('ArraySubscriptExpr',inner=[member(),node('DeclRefExpr',referencedDecl={'kind':'ParmVarDecl','id':'arg','name':'i'})])
        returned=node('ReturnStmt',range={'begin':{'offset':start},'end':{'offset':end-1,'tokLen':1}},inner=[value])
        method=node('CXXMethodDecl',name='GetValue',type={'qualType':'int (int) const'},inner=[node('ParmVarDecl',id='arg',name='i'),node('CompoundStmt',range={'begin':{'offset':0},'end':{'offset':len(source)-1,'tokLen':1}},inner=[returned])])
        return method,source
    def test_exact_indexed_const_getter_with_bound(self):
        m,s=self.getter();r=indexed_getter(m,s);self.assertEqual(r['bounds'],['GC.getNumResourceInfos()']);self.assertFalse(r['nullable'])
    def test_matching_pointer_guard_and_negative_fallback(self):
        m,s=self.getter();value=m['inner'][1]['inner'][0]['inner'][0]
        m['inner'][1]['inner'][0]['inner']=[node('ConditionalOperator',inner=[member(),value,node('UnaryOperator',opcode='-',inner=[node('IntegerLiteral',value='1')])])]
        r=indexed_getter(m,s);self.assertTrue(r['nullable']);self.assertEqual(r['null_fallback'],-1)
    def test_arbitrary_condition_or_changed_index_rejected(self):
        m,s=self.getter();value=m['inner'][1]['inner'][0]['inner'][0]
        m['inner'][1]['inner'][0]['inner']=[node('ConditionalOperator',inner=[member('other'),value,node('IntegerLiteral',value='0')])]
        self.assertIsNone(indexed_getter(m,s))
        m,s=self.getter();m['inner'][1]['inner'][0]['inner'][0]['inner'][1]['referencedDecl']['id']='different';self.assertIsNone(indexed_getter(m,s))
    def test_side_effects_missing_bounds_and_nonconst_rejected(self):
        for prefix in ['mutate();','CvAssert(i < unreviewed());', 'CvAssert(i++ < 5);']:
            m,s=self.getter(prefix=prefix);self.assertIsNone(indexed_getter(m,s))
        m,s=self.getter();m['type']['qualType']='int (int)';self.assertIsNone(indexed_getter(m,s))
    def test_nullable_assertion_free_getter_requires_loader_bound(self):
        m,s=self.getter(prefix='\n\t');value=m['inner'][1]['inner'][0]['inner'][0]
        m['inner'][1]['inner'][0]['inner']=[node('ConditionalOperator',inner=[member(),value,node('IntegerLiteral',value='0')])]
        result=indexed_getter(m,s);self.assertTrue(result['requires_loader_bound']);self.assertEqual(result['bounds'],[])
        m,s=self.getter(prefix='');self.assertIsNone(indexed_getter(m,s))
    def test_default_and_boolean_literals_remain_distinct(self):
        self.assertEqual(literal(node('CXXDefaultArgExpr'),7),7)
        self.assertEqual(literal(node('CXXBoolLiteralExpr',value=False)),0)
        self.assertIsNone(literal(node('DeclRefExpr',referencedDecl={'name':'unknown'})))
    def mapping(self,kind='PopulateArrayByExistence',pointer='bool *',conditional=False,default=None):
        getter,source=self.getter();getter['inner'][1]['inner'][0]['inner'][0]['inner'][0]['type']['qualType']=pointer
        this_type=node('CXXMemberCallExpr',inner=[node('MemberExpr',name='GetType',inner=[node('CXXThisExpr')])])
        var=node('VarDecl',id='owner',name='szType',inner=[this_type])
        strings=lambda s:node('StringLiteral',value=json.dumps(s))
        arg=member();arg['type']['qualType']=pointer
        args=[arg]+[strings(s)for s in ['Resources','Relations','ResourceType','OwnerType']]+[node('DeclRefExpr',referencedDecl={'id':'owner'})]
        if kind=='PopulateArrayByValue':args += [strings('Quantity'),node('IntegerLiteral',value=str(default or 0)),node('CXXDefaultArgExpr')]
        call=node('CXXMemberCallExpr',range={'begin':{'offset':100},'end':{'offset':200}},inner=[node('MemberExpr',name=kind)]+args)
        stmt=node('IfStmt',inner=[call])if conditional else call
        cache=node('CXXMethodDecl',name='CacheResults',inner=[node('CompoundStmt',inner=[var,stmt])])
        with tempfile.TemporaryDirectory()as temp:
            p=Path(temp)/'ast.json';p.write_text(json.dumps(getter)+'\n'+json.dumps(cache));return array_mapping(p,source)
    def test_bool_membership_and_compact_integer_lists(self):
        boolean=self.mapping()['bindings'][0];compact=self.mapping(pointer='int *')['bindings'][0]
        self.assertEqual((boolean['mode'],boolean['default']),('membership',0));self.assertEqual((compact['mode'],compact['default']),('compact-ids',-1))
    def test_value_loader_keeps_explicit_default(self):
        r=self.mapping(kind='PopulateArrayByValue',pointer='int *',default=5)['bindings'][0]
        self.assertEqual((r['mode'],r['default'],r['value_column']),('indexed-value',5,'Quantity'))
    def test_conditional_loader_remains_unmapped(self):
        r=self.mapping(conditional=True);self.assertFalse(r['bindings']);self.assertIn('unconditional',r['rejected'][0]['reason'])
if __name__=='__main__':unittest.main()
