local complete=false
local function integer(value)
 if value==nil or value==false then return 0 elseif value==true then return 1 end
 local n=assert(tonumber(value));return n<0 and math.ceil(n)or math.floor(n)
end
local function world()
 local owners={}
 for id=0,GameDefines.MAX_CIV_PLAYERS-1 do local p=Players[id]
  if p and p:IsAlive()then local units={};for u in p:Units()do units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),damage=u:GetDamage()}end
   owners[id]={gold=p:GetGold(),faith=p:GetFaith(),cities=p:GetNumCities(),units=units}
  end
 end
 return {turn=Game.GetGameTurn(),elapsed=Game.GetElapsedGameTurns(),owners=owners}
end
local function audit(record)
 local hash,count,cells=17,0,0
 for _,tableName in ipairs(tables)do
  for owner in GameInfo[tableName]()do
   for _,d in ipairs(descriptors)do if d.table==tableName then
    local actual=Game.ReadInfoArrayForTest(d.key,owner.ID);assert(#actual==d.length,"native array size differs: "..d.key)
    local expected={};for i=1,d.length do if d.mode=="membership"then expected[i]=false else expected[i]=d.default end end
    local ids={};local filter={};filter[d.owner_column]=owner.Type
    for row in GameInfo[d.relation_table](filter)do
     local reference=row[d.index_column]
     local axis=reference and GameInfo[d.index_table][reference]or nil
     if axis then
      if d.mode=="compact-ids"then ids[#ids+1]=axis.ID
      else assert(axis.ID>=0 and axis.ID<d.length,"configured index exceeds getter bound");expected[axis.ID+1]=d.mode=="membership"and true or integer(row[d.value_column])end
     end
    end
    local observed={};for i=1,d.length do observed[i]=actual[i]end
    if d.mode=="compact-ids"then
     assert(#ids<=d.length,"compact reference list exceeds getter bound")
     for i,value in ipairs(ids)do expected[i]=value end
     table.sort(expected);table.sort(observed)
    end
    for i=1,d.length do
     assert(observed[i]==expected[i],"array mismatch "..d.key.." owner="..owner.Type.." index="..(i-1).." expected="..tostring(expected[i]).." actual="..tostring(observed[i]))
     local v=type(actual[i])=="boolean"and(actual[i]and 1 or 0)or actual[i]
     hash=(hash*131+v+owner.ID+i)%2147483647;cells=cells+1
    end
    count=count+1
    print("[LEKMOD_ARRAY_CACHE] run=__TEST_RUN__ key="..d.key.." id="..owner.ID.." data="..LekmodScenarioJSON(actual))
   end end
  end
  if record then LekmodScenarioRecord("arrays-"..tableName,"PASS","actual cached indexed values/membership/compact references match resolved GameInfo")end
 end
 return {hash=hash,rows=count,cells=cells,world=world()}
end
function LekmodScenario.snapshot(player)return audit(false)end
function LekmodScenario.step(player)
 if complete then return true end
 assert(type(Game.ReadInfoArrayForTest)=="function","candidate lacks opt-in array reader")
 local key=descriptors[1].key
 for _,id in ipairs({-1,0.5,descriptors[1].owner_slots,65536,math.huge,0/0})do assert(not pcall(Game.ReadInfoArrayForTest,key,id),"invalid native array index accepted")end
 assert(not pcall(Game.ReadInfoArrayForTest,"not-a-mapped-array",0),"unknown cache key accepted")
 LekmodScenarioRecord("arrays-boundary-guards","PASS","negative/fractional/nonfinite/oversized owner IDs and unknown key reject")
 local before=LekmodScenarioJSON(world());local result=audit(true)
 assert(LekmodScenarioJSON(world())==before,"read-only cache audit changed observed gameplay state")
 LekmodScenarioRecord("arrays-read-only","PASS","all cached values checked without changing observed turn/treasury/faith/city/unit state; rows="..result.rows.." values="..result.cells)
 complete=true;return true
end
