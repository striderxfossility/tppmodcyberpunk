--[[
Ref.lua
Strong & Weak References

Copyright (c) 2021 psiberx
]]

local Ref = { version = '1.0.0' }

local weakMap
local strongMap

function Ref.IsDefined(o)
	return IsDefined(o)
end

function Ref.IsExpired(o)
	return not IsDefined(o)
end

function Ref.Equals(a, b)
	return Game['OperatorEqual;IScriptableIScriptable;Bool'](a, b)
end

function Ref.NotEquals(a, b)
	return Game['OperatorNotEqual;IScriptableIScriptable;Bool'](a, b)
end

function Ref.Weak(o)
	if not weakMap then
		weakMap = inkScriptWeakHashMap.new()
		weakMap:Insert(0, nil)
	end

	weakMap:Set(0, o)

	return weakMap:Get(0)
end

function Ref.Strong(o)
	if not strongMap then
		strongMap = inkScriptHashMap.new()
		strongMap:Insert(0, nil)
	end

	strongMap:Set(0, o)

	local ref = strongMap:Get(0)

	strongMap:Set(0, nil)

	return ref
end

function Ref.Hash(o)
	return CalcSeed(o)
end

return Ref