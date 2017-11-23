local _, NeP = ...
local _G = _G

NeP.Condition:Register('ingroup', function(target)
  return _G.UnitInParty(target) or _G.UnitInRaid(target)
end)

NeP.Condition:Register('group.members', function()
  return (_G.GetNumGroupMembers() or 0)
end)

-- USAGE: group.type==#
-- * 3 = RAID
-- * 2 = Party
-- * 1 = SOLO
NeP.Condition:Register('group.type', function()
  return _G.IsInRaid() and 3 or _G.IsInGroup() and 2 or 1
end)

local UnitClsf = {
  ['elite'] = 2,
  ['rareelite'] = 3,
  ['rare'] = 4,
  ['worldboss'] = 5
}

NeP.Condition:Register('boss', function (target)
  local classification = _G.UnitClassification(target)
  if UnitClsf[classification] then
    return UnitClsf[classification] >= 3
  end
  return NeP.BossID:Eval(target)
end)

NeP.Condition:Register('elite', function (target)
  local classification = _G.UnitClassification(target)
  if UnitClsf[classification] then
    return UnitClsf[classification] >= 2
  end
  return NeP.BossID:Eval(target)
end)

NeP.Condition:Register('id', function(target, id)
  local expectedID = tonumber(id)
  return expectedID and NeP.Core:UnitID(target) == expectedID
end)

NeP.Condition:Register('threat', function(target)
  if _G.UnitThreatSituation('player', target) then
    return select(3, _G.UnitDetailedThreatSituation('player', target))
  end
  return 0
end)

NeP.Condition:Register('aggro', function(target)
  return (_G.UnitThreatSituation(target) and _G.UnitThreatSituation(target) >= 2)
end)

NeP.Condition:Register('moving', function(target)
  local speed, _ = _G.GetUnitSpeed(target)
  return speed ~= 0
end)

NeP.Condition:Register('classification', function (target, spell)
  if not spell then return false end
  local classification = _G.UnitClassification(target)
  if string.find(spell, '[%s,]+') then
    for classificationExpected in string.gmatch(spell, '%a+') do
      if classification == string.lower(classificationExpected) then
        return true
      end
    end
    return false
  else
    return _G.UnitClassification(target) == string.lower(spell)
  end
end)

NeP.Condition:Register('target', function(target, spell)
  return ( _G.UnitGUID(target .. 'target') == _G.UnitGUID(spell) )
end)

NeP.Condition:Register('player', function(target)
  return _G.UnitIsPlayer(target)
end)

NeP.Condition:Register('exists', function(target)
  return _G.UnitExists(target)
end)

NeP.Condition:Register('dead', function (target)
  return _G.UnitIsDeadOrGhost(target)
end)

NeP.Condition:Register('alive', function(target)
  return not _G.UnitIsDeadOrGhost(target)
end)

NeP.Condition:Register('behind', function(target)
  return not NeP.Protected.Infront('player', target)
end)

NeP.Condition:Register('infront', function(target)
  return NeP.Protected.Infront('player', target)
end)

local movingCache = {}

NeP.Condition:Register('lastmoved', function(target)
  if _G.UnitExists(target) then
    local guid = _G.UnitGUID(target)
    if movingCache[guid] then
      local moving = (_G.GetUnitSpeed(target) > 0)
      if not movingCache[guid].moving and moving then
        movingCache[guid].last = _G.GetTime()
        movingCache[guid].moving = true
        return false
      elseif moving then
        return false
      elseif not moving then
        movingCache[guid].moving = false
        return _G.GetTime() - movingCache[guid].last
      end
    else
      movingCache[guid] = { }
      movingCache[guid].last = _G.GetTime()
      movingCache[guid].moving = (_G.GetUnitSpeed(target) > 0)
      return false
    end
  end
  return false
end)

NeP.Condition:Register('movingfor', function(target)
  if _G.UnitExists(target) then
    local guid = _G.UnitGUID(target)
    if movingCache[guid] then
      local moving = (_G.GetUnitSpeed(target) > 0)
      if not movingCache[guid].moving then
        movingCache[guid].last = _G.GetTime()
        movingCache[guid].moving = (_G.GetUnitSpeed(target) > 0)
        return 0
      elseif moving then
        return _G.GetTime() - movingCache[guid].last
      elseif not moving then
        movingCache[guid].moving = false
        return 0
      end
    else
      movingCache[guid] = { }
      movingCache[guid].last = _G.GetTime()
      movingCache[guid].moving = (_G.GetUnitSpeed(target) > 0)
      return 0
    end
  end
  return 0
end)

NeP.Condition:Register('friend', function(target)
  return not _G.UnitCanAttack('player', target)
end)

NeP.Condition:Register('enemy', function(target)
  return _G.UnitCanAttack('player', target)
end)

NeP.Condition:Register({'distance', 'range'}, function(unit)
  return NeP.Protected.UnitCombatRange('player', unit)
end)

NeP.Condition:Register({'distancefrom', 'rangefrom'}, function(unit, unit2)
  return NeP.Protected.UnitCombatRange(unit2, unit)
end)

NeP.Condition:Register('level', function(target)
  return _G.UnitLevel(target)
end)

NeP.Condition:Register('combat', function(target)
  return _G.UnitAffectingCombat(target)
end)

-- Checks if the player has autoattack toggled currently
-- Use {'/startattack', '!isattacking'}, at the top of a CR to force autoattacks
NeP.Condition:Register('isattacking', function()
  return _G.IsCurrentSpell(6603)
end)

NeP.Condition:Register('role', function(target, role)
  return role:upper() == _G.UnitGroupRolesAssigned(target)
end)

NeP.Condition:Register('name', function (target, expectedName)
  return _G.UnitName(target):lower():find(expectedName:lower()) ~= nil
end)

NeP.Condition:Register('creatureType', function (target, expectedType)
  return _G.UnitCreatureType(target) == expectedType
end)

NeP.Condition:Register('class', function (target, expectedClass)
  local class, _, classID = _G.UnitClass(target)
  if tonumber(expectedClass) then
    return tonumber(expectedClass) == classID
  else
    return expectedClass == class
  end
end)

NeP.Condition:Register('inmelee', function(target)
  local range = NeP.Protected.UnitCombatRange('player', target)
  return range <= 1.6, range
end)

NeP.Condition:Register('inranged', function(target)
  local range = NeP.Protected.UnitCombatRange('player', target)
  return range <= 40, range
end)

NeP.Condition:Register('incdmg', function(target, args)
  if args and _G.UnitExists(target) then
    local pDMG = NeP.CombatTracker:getDMG(target)
    return pDMG * tonumber(args)
  end
  return 0
end)

NeP.Condition:Register('incdmg.phys', function(target, args)
  if args and _G.UnitExists(target) then
    local pDMG = select(3, NeP.CombatTracker:getDMG(target))
    return pDMG * tonumber(args)
  end
  return 0
end)

NeP.Condition:Register('incdmg.magic', function(target, args)
  if args and _G.UnitExists(target) then
    local mDMG = select(4, NeP.CombatTracker:getDMG(target))
    return mDMG * tonumber(args)
  end
  return 0
end)

NeP.Condition:Register('swimming', function ()
  return _G.IsSwimming()
end)

--return if a unit is a unit
NeP.Condition:Register('is', function(a,b)
  return _G.UnitIsUnit(a,b)
end)

NeP.Condition:Register("falling", function()
  return _G.IsFalling()
end)

NeP.Condition:Register({"deathin", "ttd", "timetodie"}, function(target)
  return NeP.CombatTracker:TimeToDie(target)
end)

NeP.Condition:Register("charmed", function(target)
  return _G.UnitIsCharmed(target)
end)

local communName = NeP.Locale:TA('Dummies', 'Name')
local matchs = NeP.Locale:TA('Dummies', 'Pattern')

NeP.Condition:Register('isdummy', function(unit)
  if not _G.UnitExists(unit) then return end
  if _G.UnitName(unit):lower():find(communName) then return true end
  return NeP.Tooltip:Unit(unit, matchs)
end)

NeP.Condition:Register('indoors', function()
    return _G.IsIndoors()
end)

NeP.Condition:Register('haste', function(unit)
  return _G.UnitSpellHaste(unit)
end)

NeP.Condition:Register("mounted", function()
  return _G.IsMounted()
end)

NeP.Condition:Register('combat.time', function(target)
  return NeP.CombatTracker:CombatTime(target)
end)

NeP.Condition:Register('los', function(a, b)
  return NeP.Protected.LineOfSight(a, b)
end)