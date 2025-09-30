-- mirin template but in fnf omg
local sort = {}
sort.max_chunk_size = 32
function sort._insertion_sort_impl(array, first, last, less)
	for i = first + 1, last do
		local k = first
		local v = array[i]
		for j = i, first + 1, -1 do
			if less(v, array[j - 1]) then
				array[j] = array[j - 1]
			else
				k = j
				break
			end
		end
		array[k] = v
	end
end
function sort._merge(array, workspace, low, middle, high, less)
	local i, j, k
	i = 1
	for j = low, middle do
		workspace[i] = array[j]
		i = i + 1
	end
	i = 1
	j = middle + 1
	k = low
	while true do
		if (k >= j) or (j > high) then
			break
		end
		if less(array[j], workspace[i])  then
			array[k] = array[j]
			j = j + 1
		else
			array[k] = workspace[i]
			i = i + 1
		end
		k = k + 1
	end
	for k = k, j - 1 do
		array[k] = workspace[i]
		i = i + 1
	end
end
function sort._merge_sort_impl(array, workspace, low, high, less)
	if high - low <= sort.max_chunk_size then
		sort._insertion_sort_impl(array, low, high, less)
	else
		local middle = math.floor((low + high) / 2)
		sort._merge_sort_impl(array, workspace, low, middle, less)
		sort._merge_sort_impl(array, workspace, middle + 1, high, less)
		sort._merge(array, workspace, low, middle, high, less)
	end
end
local function default_less(a, b)
	return a < b
end
function sort._sort_setup(array, less)
	less = less or default_less
	local n = #array
	local trivial = (n <= 1)
	if not trivial then
		if less(array[1], array[1]) then
			error('invalid order function for sorting; less(v, v) should not be true for any v.')
		end
	end
	return trivial, n, less
end
function sort.stable_sort(array, less)
	local trivial, n, less = sort._sort_setup(array, less)
	if not trivial then
		local workspace = {}
		local middle = math.ceil(n / 2)
		workspace[middle] = array[1]
		sort._merge_sort_impl( array, workspace, 1, n, less )
	end
	return array
end
function sort.insertion_sort(array, less)
	local trivial, n, less = sort._sort_setup(array, less)
	if not trivial then
		sort._insertion_sort_impl(array, 1, n, less)
	end
	return array
end
unstable_sort = table.sort
stable_sort = sort.stable_sort
local sqrt = math.sqrt
local sin = math.sin
local asin = math.asin
local cos = math.cos
local pow = math.pow
local exp = math.exp
local pi = math.pi
local abs = math.abs
flip = setmetatable({}, {
	__call = function(self, fn)
		self[fn] = self[fn] or function(x) return 1 - fn(x) end
		return self[fn]
	end
})
blendease = setmetatable({}, {
	__index = function(self, key)
		self[key] = {}
		return self[key]
	end,
	__call = function(self, fn1, fn2)
		if not self[fn1][fn2] then
			local transient1 = fn1(1) <= 0.5
			local transient2 = fn2(1) <= 0.5
			if transient1 and not transient2 then
				error('blendease: the first argument is a transient ease, but the second argument doesn\'t match')
			end
			if transient2 and not transient1 then
				error('blendease: the second argument is a transient ease, but the first argument doesn\'t match')
			end
			self[fn1][fn2] = function(x)
				local mixFactor = 3*x^2-2*x^3
				return (1 - mixFactor) * fn1(x) + mixFactor * fn2(x)
			end
		end
		return self[fn1][fn2]
	end
})
local function param1cache(self, param1)
	self.cache[param1] = self.cache[param1] or function(x)
		return self.fn(x, param1)
	end
	return self.cache[param1]
end
local param1mt = {
	__call = function(self, x, param1)
		return self.fn(x, param1 or self.dp1)
	end,
	__index = {
		param = param1cache,
		params = param1cache,
	}
}
function with1param(fn, defaultparam1)
	return setmetatable({
		fn = fn,
		dp1 = defaultparam1,
		cache = {},
	}, param1mt)
end
local function param2cache(self, param1, param2)
	self.cache[param1] = self.cache[param1] or {}
	self.cache[param1][param2] = self.cache[param1][param2] or function(x)
		return self.fn(x, param1, param2)
	end
	return self.cache[param1][param2]
end

local param2mt = {
	__call = function(self, x, param1, param2)
		return self.fn(x, param1 or self.dp1, param2 or self.dp2)
	end,
	__index = {
		param=param2cache,
		params=param2cache,
	}
}
function with2params(fn, defaultparam1, defaultparam2)
	return setmetatable({
		fn = fn,
		dp1 = defaultparam1,
		dp2 = defaultparam2,
		cache = {},
	}, param2mt)
end
function bounce(t) return 4 * t * (1 - t) end
function tri(t) return 1 - abs(2 * t - 1) end
function bell(t) return inOutQuint(tri(t)) end
function pop(t) return 3.5 * (1 - t) * (1 - t) * sqrt(t) end
function tap(t) return 3.5 * t * t * sqrt(1 - t) end
function pulse(t) return t < .5 and tap(t * 2) or -pop(t * 2 - 1) end

function spike(t) return exp(-10 * abs(2 * t - 1)) end
function inverse(t) return t * t * (1 - t) * (1 - t) / (0.5 - t) end

local function popElasticInternal(t, damp, count)
	return (1000 ^ -(t ^ damp) - 0.001) * sin(count * pi * t)
end

local function tapElasticInternal(t, damp, count)
	return (1000 ^ -((1 - t) ^ damp) - 0.001) * sin(count * pi * (1 - t))
end

local function pulseElasticInternal(t, damp, count)
	if t < .5 then
		return tapElasticInternal(t * 2, damp, count)
	else
		return -popElasticInternal(t * 2 - 1, damp, count)
	end
end
popElastic = with2params(popElasticInternal, 1.4, 6)
tapElastic = with2params(tapElasticInternal, 1.4, 6)
pulseElastic = with2params(pulseElasticInternal, 1.4, 6)
impulse = with1param(function(t, damp)
	t = t ^ damp
	return t * (1000 ^ -t - 0.001) * 18.6
end, 0.9)
function instant() return 1 end
function linear(t) return t end
function inQuad(t) return t * t end
function outQuad(t) return -t * (t - 2) end
function inOutQuad(t)
	t = t * 2
	if t < 1 then
		return 0.5 * t ^ 2
	else
		return 1 - 0.5 * (2 - t) ^ 2
	end
end
function outInQuad(t)
	t = t * 2
	if t < 1 then
		return 0.5 - 0.5 * (1 - t) ^ 2
	else
		return 0.5 + 0.5 * (t - 1) ^ 2
	end
end
function inCubic(t) return t * t * t end
function outCubic(t) return 1 - (1 - t) ^ 3 end
function inOutCubic(t)
	t = t * 2
	if t < 1 then
		return 0.5 * t ^ 3
	else
		return 1 - 0.5 * (2 - t) ^ 3
	end
end
function outInCubic(t)
	t = t * 2
	if t < 1 then
		return 0.5 - 0.5 * (1 - t) ^ 3
	else
		return 0.5 + 0.5 * (t - 1) ^ 3
	end
end
function inQuart(t) return t * t * t * t end
function outQuart(t) return 1 - (1 - t) ^ 4 end
function inOutQuart(t)
	t = t * 2
	if t < 1 then
		return 0.5 * t ^ 4
	else
		return 1 - 0.5 * (2 - t) ^ 4
	end
end
function outInQuart(t)
	t = t * 2
	if t < 1 then
		return 0.5 - 0.5 * (1 - t) ^ 4
	else
		return 0.5 + 0.5 * (t - 1) ^ 4
	end
end
function inQuint(t) return t ^ 5 end
function outQuint(t) return 1 - (1 - t) ^ 5 end
function inOutQuint(t)
	t = t * 2
	if t < 1 then
		return 0.5 * t ^ 5
	else
		return 1 - 0.5 * (2 - t) ^ 5
	end
end
function outInQuint(t)
	t = t * 2
	if t < 1 then
		return 0.5 - 0.5 * (1 - t) ^ 5
	else
		return 0.5 + 0.5 * (t - 1) ^ 5
	end
end
function inExpo(t) return 1000 ^ (t - 1) - 0.001 end
function outExpo(t) return 1.001 - 1000 ^ -t end
function inOutExpo(t)
	t = t * 2
	if t < 1 then
		return 0.5 * 1000 ^ (t - 1) - 0.0005
	else
		return 1.0005 - 0.5 * 1000 ^ (1 - t)
	end
end
function outInExpo(t)
	if t < 0.5 then
		return outExpo(t * 2) * 0.5
	else
		return inExpo(t * 2 - 1) * 0.5 + 0.5
	end
end
function inCirc(t) return 1 - sqrt(1 - t * t) end
function outCirc(t) return sqrt(-t * t + 2 * t) end
function inOutCirc(t)
	t = t * 2
	if t < 1 then
		return 0.5 - 0.5 * sqrt(1 - t * t)
	else
		t = t - 2
		return 0.5 + 0.5 * sqrt(1 - t * t)
	end
end
function outInCirc(t)
	if t < 0.5 then
		return outCirc(t * 2) * 0.5
	else
		return inCirc(t * 2 - 1) * 0.5 + 0.5
	end
end
function outBounce(t)
	if t < 1 / 2.75 then
		return 7.5625 * t * t
	elseif t < 2 / 2.75 then
		t = t - 1.5 / 2.75
		return 7.5625 * t * t + 0.75
	elseif t < 2.5 / 2.75 then
		t = t - 2.25 / 2.75
		return 7.5625 * t * t + 0.9375
	else
		t = t - 2.625 / 2.75
		return 7.5625 * t * t + 0.984375
	end
end
function inBounce(t) return 1 - outBounce(1 - t) end
function inOutBounce(t)
	if t < 0.5 then
		return inBounce(t * 2) * 0.5
	else
		return outBounce(t * 2 - 1) * 0.5 + 0.5
	end
end
function outInBounce(t)
	if t < 0.5 then
		return outBounce(t * 2) * 0.5
	else
		return inBounce(t * 2 - 1) * 0.5 + 0.5
	end
end
function inSine(x) return 1 - cos(x * (pi * 0.5)) end
function outSine(x) return sin(x * (pi * 0.5)) end
function inOutSine(x)
	return 0.5 - 0.5 * cos(x * pi)
end
function outInSine(t)
	if t < 0.5 then
		return outSine(t * 2) * 0.5
	else
		return inSine(t * 2 - 1) * 0.5 + 0.5
	end
end
function outElasticInternal(t, a, p)
	return a * pow(2, -10 * t) * sin((t - p / (2 * pi) * asin(1/a)) * 2 * pi / p) + 1
end
local function inElasticInternal(t, a, p)
	return 1 - outElasticInternal(1 - t, a, p)
end
function inOutElasticInternal(t, a, p)
	return t < 0.5
		and  0.5 * inElasticInternal(t * 2, a, p)
		or  0.5 + 0.5 * outElasticInternal(t * 2 - 1, a, p)
end
function outInElasticInternal(t, a, p)
	return t < 0.5
		and  0.5 * outElasticInternal(t * 2, a, p)
		or  0.5 + 0.5 * inElasticInternal(t * 2 - 1, a, p)
end
inElastic = with2params(inElasticInternal, 1, 0.3)
outElastic = with2params(outElasticInternal, 1, 0.3)
inOutElastic = with2params(inOutElasticInternal, 1, 0.3)
outInElastic = with2params(outInElasticInternal, 1, 0.3)
function inBackInternal(t, a) return t * t * (a * t + t - a) end
function outBackInternal(t, a) t = t - 1 return t * t * ((a + 1) * t + a) + 1 end
function inOutBackInternal(t, a)
	return t < 0.5
		and  0.5 * inBackInternal(t * 2, a)
		or  0.5 + 0.5 * outBackInternal(t * 2 - 1, a)
end
function outInBackInternal(t, a)
	return t < 0.5
		and  0.5 * outBackInternal(t * 2, a)
		or  0.5 + 0.5 * inBackInternal(t * 2 - 1, a)
end
inBack = with1param(inBackInternal, 1.70158)
outBack = with1param(outBackInternal, 1.70158)
inOutBack = with1param(inOutBackInternal, 1.70158)
outInBack = with1param(outInBackInternal, 1.70158)
local max_pn = 8
local default_plr = {1, 2}
function get_plr()
	return default_plr
end
local stringbuilder_mt =  {
	__index = {
		build = table.concat,
		clear = iclear,
	},
	__call = function(self, a)
		table.insert(self, tostring(a))
		return self
	end,
	__tostring = table.concat,
}
function stringbuilder()
	return setmetatable({}, stringbuilder_mt)
end
function copy(src)
	local dest = {}
	for k, v in pairs(src) do
		dest[k] = v
	end
	return dest
end
local default_mods = {}
setmetatable(default_mods, {
	__index = function(self, i)
		self[i] = 0
		return 0
	end
})
local targets = {}
local targets_mt = {__index = default_mods}
for pn = 1, max_pn do
	targets[pn] = setmetatable({}, targets_mt)
end
local mods = {}
local mods_mt = {}
for pn = 1, max_pn do
	mods_mt[pn] = {__index = targets[pn]}
	mods[pn] = setmetatable({}, mods_mt[pn])
end
local mod_buffer = {}
for pn = 1, max_pn do
	mod_buffer[pn] = stringbuilder()
end
local eases = {}
local auxes = {}
function ease(self)
	self.mode = self.mode == 'end' or self.m == 'e'
	if self.mode then
		self[2] = self[2] - self[1]
	end
	self.start_time = self.time and self[1] or getTimeFromBeat(self[1])
	local plr = self.plr or get_plr()
	if type(plr) == 'table' then
		for _, plr in ipairs(plr) do
			local new = copy(self)
			new.plr = plr
			table.insert(eases, new)
		end
	else
		self.plr = plr
		table.insert(eases, self)
	end
end
function add(self)
	self.relative = true
	ease(self)
end
function set(self)
	table.insert(self, 2, 0)
	table.insert(self, 3, instant)
	ease(self)
end
function acc(self)
	self.relative = true
	table.insert(self, 2, 0)
	table.insert(self, 3, instant)
	ease(self)
end
function reset(self)
	self[2] = self[2] or 0
	self[3] = self[3] or instant
	self.reset = true
	if self.only then
		if type(self.only) == 'string' then
			self.only = {self.only}
		end
	elseif self.exclude then
		if type(self.exclude) == 'string' then
			self.exclude = {self.exclude}
		end
		local exclude = {}
		for _, v in ipairs(self.exclude) do
			exclude[v] = true
		end
		self.exclude = exclude
	end
	ease(self)
end
function aux(self)
	if type(self) == 'string' then
		local v = self
		auxes[v] = true
	elseif type(self) == 'table' then
		for i = 1, #self do
			aux(self[i])
		end
	end
	return aux
end
function touch_mod(mod, pn)
	if pn then
		mods[pn][mod] = mods[pn][mod]
	else
		for pn = 1, max_pn do
			touch_mod(mod, pn)
		end
	end
end
local eases_index = 1
local active_eases = {}
function run_eases(beat, time)
	while eases_index <= #eases do
		local e = eases[eases_index]
		local measure = e.time and time or beat
		if measure < e[1] then break end
		local plr = e.plr
		if e.reset then
			if e.only then
				for _, mod in ipairs(e.only) do
					table.insert(e, default_mods[mod])
					table.insert(e, mod)
				end
			else
				for mod in pairs(targets[plr]) do
					if not(e.exclude and e.exclude[mod]) and targets[plr][mod] ~= default_mods[mod] then
						table.insert(e, default_mods[mod])
						table.insert(e, mod)
					end
				end
			end
		end
		local ease_ends_at_different_position = e[3](1) >= 0.5
		e.offset = ease_ends_at_different_position and 1 or 0
		for i = 4, #e, 2 do
			if not e.relative then
				local mod = e[i + 1]
				e[i] = e[i] - targets[plr][mod]
			end
			if ease_ends_at_different_position then
				local mod = e[i + 1]
				targets[plr][mod] = targets[plr][mod] + e[i]
			end
		end
		table.insert(active_eases, e)
		eases_index = eases_index + 1
	end
	local active_eases_index = 1
	while active_eases_index <= #active_eases do
		local e = active_eases[active_eases_index]
		local plr = e.plr
		local measure = e.time and time or beat
		if measure < e[1] + e[2] then
			local e3 = e[3]((measure - e[1]) / e[2]) - e.offset
			for i = 4, #e, 2 do
				local mod = e[i + 1]
				mods[plr][mod] = mods[plr][mod] + e3 * e[i]
			end
			active_eases_index = active_eases_index + 1
		else
			for i = 4, #e, 2 do
				local mod = e[i + 1]
				touch_mod(mod, plr)
			end
			if active_eases_index ~= #active_eases then
				active_eases[active_eases_index] = table.remove(active_eases)
			else
				table.remove(active_eases)
			end
		end
	end
end
function run_mods()
	for pn = 1, max_pn do
			local buffer = mod_buffer[pn]
			for mod, percent in pairs(mods[pn]) do
				if not auxes[mod] then
					buffer('*-1 '..percent..' '..mod)
				end
				mods[pn][mod] = nil
			end
			if buffer[1] then
				ApplyModifiers(buffer:build(','), pn)
				buffer:clear()
			end
	end
end
function sort_tables()
	stable_sort(eases, function(a, b)
		if a.start_time == b.start_time then
			return a.reset and not b.reset
		else
			return a.start_time < b.start_time
		end
	end)
end

function initMods()
	-- write mods here
end

function onInit()
	initMods()
  sort_tables()
	for i = 1, max_pn do
		mod_buffer[i]:clear()
	end
	run_mods()
end
function onUpdate()
  run_eases(getBeat(), getTime())
  run_mods()
end
