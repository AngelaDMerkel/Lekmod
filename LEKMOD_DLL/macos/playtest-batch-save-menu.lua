-- Acknowledge the returned save request, not completion of its asynchronous write.
-- The host verifies closed writer handles and stable source/copy bytes before load.
do
 local name,elapsed=nil,0
 LuaEvents.LekmodFunctionalSaveName.Add(function(value)name=value;elapsed=0 end)
 ContextPtr:SetUpdate(function(dt)
  if not name then return end
  elapsed=elapsed+dt;if elapsed<2 then return end
  local value=name;name=nil
  local ok,err=pcall(function()
   assert(not ContextPtr:IsHidden(),"save menu did not open")
   assert(not Controls.CloudCheck:IsChecked(),"batch saves must stay local")
   assert(g_SelectedEntry==nil,"existing save selected")
   for _,entry in ipairs(g_SavedGames)do assert(entry.DisplayName~=value,"refusing checkpoint overwrite")end
   Controls.NameBox:SetText(value);OnSave()
   assert(Controls.DeleteConfirm:IsHidden(),"unexpected overwrite confirmation")
   print('[LEKMOD_BATCH] run=__TEST_RUN__ event=saved value="'..value..'"')
   LuaEvents.LekmodBatchSaved(value)
  end)
  if not ok then print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=batch-save status=FAIL error="..tostring(err))end
 end)
end
