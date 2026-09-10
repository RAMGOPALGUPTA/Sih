from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import Literal
from uuid import UUID, uuid4
from datetime import datetime, timezone
import hashlib, json, os
import psycopg

app=FastAPI(title='SIH Field Testing API',version='1.0.0')
DB=os.getenv('DATABASE_URL','postgresql://sih:sih_dev@localhost:5432/sih')
Classification=Literal['positive','negative','inconclusive']
class CaseIn(BaseModel):
    id: UUID|None=None; operator_id:str='demo-operator'; classification:Classification; confidence:float=Field(ge=0,le=1)
    latitude:float|None=None; longitude:float|None=None; captured_at:datetime; model_version:str; app_version:str
    image_sha256:str=Field(min_length=64,max_length=64)

def canonical(c):
    d={'id':str(c.id),'operator_id':c.operator_id,'classification':c.classification,'confidence':c.confidence,'latitude':c.latitude,'longitude':c.longitude,'captured_at':c.captured_at.isoformat(),'model_version':c.model_version,'app_version':c.app_version,'image_sha256':c.image_sha256}
    return json.dumps(d,sort_keys=True,separators=(',',':'))
def digest(c): return hashlib.sha256(canonical(c).encode()).hexdigest()

def conn(): return psycopg.connect(DB)
@app.get('/health')
def health():
    try:
        with conn() as x: x.execute('SELECT 1')
        return {'status':'ok'}
    except Exception as e: raise HTTPException(503,str(e))
@app.get('/api/v1/cases')
def list_cases(limit:int=100):
    with conn() as x:
        rows=x.execute('SELECT id,operator_id,classification,confidence,latitude,longitude,captured_at,model_version,app_version FROM cases ORDER BY captured_at DESC LIMIT %s',(limit,)).fetchall()
    return [{'id':str(r[0]),'operator_id':r[1],'classification':r[2],'confidence':r[3],'latitude':r[4],'longitude':r[5],'captured_at':r[6],'model_version':r[7],'app_version':r[8]} for r in rows]
@app.post('/api/v1/cases')
def create_case(c:CaseIn):
    cid=c.id or uuid4(); c.id=cid; p=digest(c)
    with conn() as x:
        try:
            x.execute("INSERT INTO cases(id,operator_id,classification,confidence,latitude,longitude,captured_at,model_version,app_version) VALUES(%s,%s,%s,%s,%s,%s,%s,%s,%s) ON CONFLICT(id) DO NOTHING",(cid,c.operator_id,c.classification,c.confidence,c.latitude,c.longitude,c.captured_at,c.model_version,c.app_version))
            x.execute("INSERT INTO evidence(case_id,image_sha256,payload_sha256) VALUES(%s,%s,%s) ON CONFLICT(case_id) DO UPDATE SET image_sha256=EXCLUDED.image_sha256,payload_sha256=EXCLUDED.payload_sha256",(cid,c.image_sha256,p))
            x.execute("INSERT INTO audit_log(case_id,operator_id,action,details) VALUES(%s,%s,%s,%s)",(cid,c.operator_id,'case_created',json.dumps({'classification':c.classification})))
        except Exception: x.rollback(); raise
    return {'id':str(cid),'payload_sha256':p}
@app.get('/api/v1/cases/{case_id}/verify')
def verify(case_id:UUID):
    with conn() as x:
        r=x.execute('SELECT c.id,c.operator_id,c.classification,c.confidence,c.latitude,c.longitude,c.captured_at,c.model_version,c.app_version,e.image_sha256,e.payload_sha256 FROM cases c JOIN evidence e ON e.case_id=c.id WHERE c.id=%s',(case_id,)).fetchone()
    if not r: raise HTTPException(404,'case not found')
    class Obj: pass
    o=Obj();
    for k,v in zip(['id','operator_id','classification','confidence','latitude','longitude','captured_at','model_version','app_version','image_sha256'],r[:10]): setattr(o,k,v)
    actual=digest(o)
    return {'case_id':str(case_id),'valid':actual==r[10],'recorded_payload_sha256':r[10],'computed_payload_sha256':actual,'image_sha256':r[9]}
