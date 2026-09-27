-- Scripted original Confirm callback for an explicitly armed city-attack warning.
-- No direct combat-warning, synchronization, popup semaphore or preference edits.
do
 local armed,pending,elapsed
 LuaEvents.LekmodAdvisorAttackConfirm.Add(function(index,owner,unit)
  assert(not armed and not pending,"advisor request already pending")
  armed={index=index,owner=owner,unit=unit}
 end)
 Events.SerialEventGameMessagePopup.Add(function(info)
  if not armed or info.Type~=ButtonPopupTypes.BUTTONPOPUP_ADVISOR_MODAL then return end
  assert(info.Option1 and info.Data2==armed.index,"unexpected advisor warning target")
  pending=armed;armed=nil;elapsed=0
 end)
 ContextPtr:SetUpdate(function(dt)
  if not pending or ContextPtr:IsHidden()or Game.IsProcessingMessages()then return end
  elapsed=elapsed+dt;if elapsed<0.5 then return end
  local request=pending;pending=nil
  local ok,err=pcall(function()
   local u=assert(UI.GetHeadSelectedUnit())
   assert(u:GetOwner()==request.owner and u:GetID()==request.unit,"advisor selection changed")
   assert(not Controls.DontShowAgainCheckbox:IsChecked(),"advisor preference must remain unchanged")
   OnConfirmButtonClicked()
   LuaEvents.LekmodAdvisorAttackConfirmed(request.index,request.owner,request.unit)
  end)
  if not ok then print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=advisor-attack-confirm status=FAIL error="..tostring(err))end
 end)
end
