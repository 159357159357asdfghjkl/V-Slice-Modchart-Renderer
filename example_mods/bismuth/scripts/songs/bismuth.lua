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
function deepcopy(src)
	local dest = {}
	for k, v in pairs(src) do
		local k, v = k, v
		if type(k) == 'table' then k = deepcopy(k) end
		if type(v) == 'table' then v = deepcopy(v) end
		dest[k] = v
	end
	return dest
end
function clear(t)
	for k, v in pairs(t) do
		t[k] = nil
	end
	return t
end
function iclear(t)
	for i = 1, #t do
		table.remove(t)
	end
	return t
end
local methods = {}
function methods:add(obj)
	local stage = self.stage
	self.n = self.n + 1
	stage.n = stage.n + 1
	stage[stage.n] = obj
end
function methods:remove()
	local swap = self.swap
	swap[swap.n] = nil
	swap.n = swap.n - 1
	self.n = self.n - 1
end
function methods:next()
	if self.n == 0 then return end
	local swap = self.swap
	local stage = self.stage
	local list = self.list
	if swap.n == 0 then
		stable_sort(stage, self.reverse_comparator)
	end
	if stage.n == 0 then
		if list.n == 0 then
			while swap.n ~= 0 do
				list.n = list.n + 1
				list[list.n] = swap[swap.n]
				swap[swap.n] = nil
				swap.n = swap.n - 1
			end
		else
			swap.n = swap.n + 1
			swap[swap.n] = list[list.n]
			list[list.n] = nil
			list.n = list.n - 1
		end
	else
		if list.n == 0 then
			swap.n = swap.n + 1
			swap[swap.n] = stage[stage.n]
			stage[stage.n] = nil
			stage.n = stage.n - 1
		else
			if self.comparator(list[list.n], stage[stage.n]) then
				swap.n = swap.n + 1
				swap[swap.n] = list[list.n]
				list[list.n] = nil
				list.n = list.n - 1
			else
				swap.n = swap.n + 1
				swap[swap.n] = stage[stage.n]
				stage[stage.n] = nil
				stage.n = stage.n - 1
			end
		end
	end
	return swap[swap.n]
end
local mt = {__index = methods}
function perframe_data_structure(comparator)
	return setmetatable({
		comparator = comparator,
		reverse_comparator = function(a, b) return comparator(b, a) end,
		stage = {n = 0},
		list = {n = 0},
		swap = {n = 0},
		n = 0,
	}, mt)
end
function copy(src)
	local dest = {}
	for k, v in pairs(src) do
		dest[k] = v
	end
	return dest
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
local max_pn = 8
local touched_mods = {}
for pn = 1, max_pn do
	touched_mods[pn] = {}
end
local default_mods = {}
setmetatable(default_mods, {
	__index = function(self, i)
		self[i] = 0
		return 0
	end
})
local eases = {}
local funcs = {}
local auxes = {}
local aliases = {}
local nodes = {}
local default_plr = {1, 2}
function get_plr()
	return default_plr
end

local banned_chars = {}
local _ = string.gsub('\'\\{}(),;* ', '.', function(t)
	banned_chars[t] = true
end)
local function ensure_mod_name_is_valid(name)
	if banned_chars[string.sub(name, 1, 1)] or banned_chars[string.sub(name, #name, #name)] then
		error(
			'You have a typo in your mod name. '..
			'You wrote \''..name..'\', but you probably meant '..
			'\''..string.gsub(name, '[\'\\{}(),;* ]', '')..'\''
		)
	end
	if string.find(name, '^c[0-9]+$') then
		error(
			'You can\'t name your mod \''..name..'\'.\n'..
			'Use \'cmod\' if you want to set a cmod.'
		)
	end
	if string.find(name, '^[0-9.]+x$') then
		error(
			'You can\'t name your mod \''..name..'\'.\n'..
			'Use \'xmod\' if you want to set an xmod.'
		)
	end
end
local function normalize_mod_no_checks(name)
	name = string.lower(name)
	return aliases[name] or name
end
local function normalize_mod(name)
	if not auxes[name] then ensure_mod_name_is_valid(name) end
	return normalize_mod_no_checks(name)
end
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
	return ease
end
function add(self)
	self.relative = true
	ease(self)
	return add
end
function set(self)
	table.insert(self, 2, 0)
	table.insert(self, 3, instant)
	ease(self)
	return set
end
function acc(self)
	self.relative = true
	table.insert(self, 2, 0)
	table.insert(self, 3, instant)
	ease(self)
	return acc
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
	return reset
end
function func_function(self)
	if type(self[2]) == 'string' then
		local args, syms = {}, {}
		for i = 1, #self - 2 do
			syms[i] = 'arg' .. i
			args[i] = self[i + 2]
		end
		local symstring = table.concat(syms, ', ')
		local code = 'return function('..symstring..') return function() '..self[2]..'('..symstring..') end end'
		self[2] = assert(loadstring(code, 'func_generated'))()(unpack(args))
		while self[3] do
			table.remove(self)
		end
	end
	self[2], self[3] = nil, self[2]
	local persist = self.persist
	self.mode = self.mode == 'end' or self.m == 'e'
	if type(persist) == 'number' and self.mode then
		persist = persist - self[1]
	end
	if persist == false then
		persist = 0.5
	end
	if type(persist) == 'number' then
		local fn = self[3]
		local final_time = self[1] + persist
		self[3] = function(beat)
			if beat < final_time then
				fn(beat)
			end
		end
	end
	self.priority = (self.defer and -1 or 1) * (#funcs + 1)
	self.start_time = self.time and self[1] or getTimeFromBeat(self[1])
	table.insert(funcs, self)
end
local disallowed_poptions_perframe_persist = setmetatable({}, {__index = function(_)
	error('you cannot use poptions and persist at the same time. </3')
end})
function func_perframe(self, deny_poptions)
	if self.mode then
		self[2] = self[2] - self[1]
	end
	if not deny_poptions then
		self.mods = {}
		for pn = 1, max_pn do
			self.mods[pn] = {}
		end
	end
	self.priority = (self.defer and -1 or 1) * (#funcs + 1)
	self.start_time = self.time and self[1] or getTimeFromBeat(self[1])

	local persist = self.persist
	if persist then
		if type(persist) == 'number' and self.mode then
			persist = persist - self[1] - self[2]
		end
		func_function {
			self[1] + self[2],
			function()
				self[3](getBeat(), disallowed_poptions_perframe_persist)
			end,
			persist = self.persist,
		}
		end
	table.insert(funcs, self)
end
function func_ease(self)
	self.mode = self.mode == 'end' or self.m == 'e'
	if self.mode then
		self[2] = self[2] - self[1]
	end
	local fn = table.remove(self)
	local eas = self[3]
	local start_percent = #self >= 5 and table.remove(self, 4) or 0
	local end_percent = #self >= 4 and table.remove(self, 4) or 1
	local end_beat = self[1] + self[2]
	if type(fn) == 'string' then
		fn = assert(loadstring('return function(p) '..fn..'(p) end', 'func_generated'))()
	end
	self[3] = function(beat)
		local progress = (beat - self[1]) / self[2]
		fn(start_percent + (end_percent - start_percent) * eas(progress))
	end
	if self.persist ~= false then
		local final_percent = eas(1) > 0.5 and end_percent or start_percent
		func {
			end_beat,
			function()
				fn(final_percent)
			end,
			persist = self.persist,
			defer = self.defer,
		}
	end
	self.persist = false
	func_perframe(self, true)
end
function func(self)
	if type(self[2]) == 'string' or #self == 2 then
		func_function(self)
	elseif #self == 3 then
		func_perframe(self, true)
	else
		func_ease(self)
	end
	return func
end
function alias(self)
	local a, b = self[1], self[2]
	a, b = string.lower(a), string.lower(b)
	aliases[a] = b
	return alias
end
function setdefault(self)
	for i = 1, #self, 2 do
		default_mods[self[i + 1]] = self[i]
	end
	return setdefault
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
function node(self)
	if type(self[2]) == 'number' then
		local multipliers = {}
		local i = 2
		while self[i] do
			local amt = string.format('p * %f', table.remove(self, i) * 0.01)
			table.insert(multipliers, amt)
			i = i + 1
		end
		local ret = table.concat(multipliers, ', ')
		local code = 'return function(p) return '..ret..' end'
		local fn = loadstring(code, 'node_generated')()
		table.insert(self, 2, fn)
	end
	local i = 1
	local inputs = {}
	while type(self[i]) == 'string' do
		table.insert(inputs, self[i])
		i = i + 1
	end
	local fn = self[i]
	i = i + 1
	local out = {}
	while self[i] do
		table.insert(out, self[i])
		i = i + 1
	end
	local result = {inputs, out, fn}
	result.priority = (self.defer and -1 or 1) * (#nodes + 1)
	table.insert(nodes, result)
	return node
end
function definemod(self)
	for i = 1, #self do
		if type(self[i]) ~= 'string' then
			break
		end
		aux(self[i])
	end
	node(self)
	return definemod
end
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
local node_start = {}
local poptions = {}
local poptions_logging_target
for pn = 1, max_pn do
	local pn = pn
	local mods_pn = mods[pn]
	local mt = {
		__index = function(_, k)
			return mods_pn[normalize_mod_no_checks(k)]
		end,
		__newindex = function(_, k, v)
			k = normalize_mod_no_checks(k)
			mods_pn[k] = v
			--if v then
				--poptions_logging_target[pn][k] = true
			--end
		end,
	}
	poptions[pn] = setmetatable({}, mt)
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
function sort_tables()
	stable_sort(eases, function(a, b)
		if a.start_time == b.start_time then
			return a.reset and not b.reset
		else
			return a.start_time < b.start_time
		end
	end)
	stable_sort(funcs, function(a, b)
		if a.start_time == b.start_time then
			local x, y = a.priority, b.priority
			return x * x * y < x * y * y
		else
			return a.start_time < b.start_time
		end
	end)
	stable_sort(nodes, function(a, b)
		local x, y = a.priority, b.priority
		return x * x * y < x * y * y
	end)
end
function resolve_aliases()
	local old_auxes = copy(auxes)
	clear(auxes)
	for mod, _ in pairs(old_auxes) do
		auxes[normalize_mod_no_checks(mod)] = true
	end
	for _, e in ipairs(eases) do
		for i = 5, #e, 2 do
			e[i] = normalize_mod(e[i])
		end
		if e.exclude then
			local exclude = {}
			for k, v in pairs(e.exclude) do
				exclude[normalize_mod(k)] = v
			end
			e.exclude = exclude
		end
		if e.only then
			for i = 1, #e.only do
				e.only[i] = normalize_mod(e.only[i])
			end
		end
	end
	for _, node_entry in ipairs(nodes) do
		local input = node_entry[1]
		local output = node_entry[2]
		for i = 1, #input do input[i] = normalize_mod(input[i]) end
		for i = 1, #output do output[i] = normalize_mod(output[i]) end
	end
	local old_default_mods = copy(default_mods)
	clear(default_mods)
	for mod, percent in pairs(old_default_mods) do
		local normalized = normalize_mod(mod)
		default_mods[normalized] = percent
		for pn = 1, max_pn do
			touched_mods[pn][normalized] = true
		end
	end
end
function compile_nodes()
	local terminators = {}
	for _, nd in ipairs(nodes) do
		for _, mod in ipairs(nd[2]) do
			terminators[mod] = true
		end
	end
	local priority = -1 * (#nodes + 1)
	for k, _ in pairs(terminators) do
		table.insert(nodes, {{k}, {}, nil, nil, nil, nil, nil, true, priority = priority})
	end
	local start = node_start
	local locked = {}
	local last = {}
	for _, nd in ipairs(nodes) do
		local terminator = nd[8]
		if not terminator then
			nd[4] = {}
			nd[7] = {}
			for pn = 1, max_pn do
				nd[7][pn] = {}
			end
		end
		nd[5] = {}
		local inputs = nd[1]
		local out = nd[2]
		local fn = nd[3]
		local parents = nd[5]
		local outputs = nd[7]
		local reverse_in = {}
		for i, v in ipairs(inputs) do
			reverse_in[v] = true
			start[v] = start[v] or {}
			parents[i] = {}
			if not start[v][locked] then
				table.insert(start[v], nd)
			end
			if start[v][locked] then
				parents[i][0] = true
			end
			for _, pre in ipairs(last[v] or {}) do
				table.insert(pre[4], nd)
				table.insert(parents[i], pre[7])
			end
		end
		for _, v in ipairs(out) do
			if reverse_in[v] then
				start[v][locked] = true
				last[v] = {nd}
			elseif not last[v] then
				last[v] = {nd}
			else
				table.insert(last[v], nd)
			end
		end
		local function escapestr(s)
			return '\'' .. string.gsub(s, '[\\\']', '\\%1') .. '\''
		end
		local function list(code, i, sep)
			if i ~= 1 then code(sep) end
		end
		local code = stringbuilder()
		local function emit_inputs()
			for i, mod in ipairs(inputs) do
				list(code, i, ',')
				for j = 1, #parents[i] do
					list(code, j, '+')
					code'parents['(i)']['(j)'][pn]['(escapestr(mod))']'
				end
				if not parents[i][0] then
					list(code, #parents[i] + 1, '+')
					code'mods[pn]['(escapestr(mod))']'
				end
			end
		end
		local function emit_outputs()
			for i, mod in ipairs(out) do
				list(code, i, ',')
				code'outputs[pn]['(escapestr(mod))']'
			end
			return out[1]
		end
		code
		'return function(outputs, parents, mods, fn)\n'
			'return function(pn)\n'
				if terminator then
					code'mods[pn]['(escapestr(inputs[1]))'] = ' emit_inputs() code'\n'
				else
					if emit_outputs() then code' = ' end code 'fn(' emit_inputs() code', pn)\n'
				end
				code
			'end\n'
		'end\n'
		local compiled = assert(loadstring(code:build(), 'node_generated'))()
		nd[6] = compiled(outputs, parents, mods, fn)
		if not terminator then
			for pn = 1, max_pn do
				nd[6](pn)
			end
		end
	end
	for mod, v in pairs(start) do
		v[locked] = nil
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

local funcs_index = 1
local active_funcs = perframe_data_structure(function(a, b)
	local x, y = a.priority, b.priority
	return x * x * y < x * y * y
end)
local function run_funcs(beat, time)
	while funcs_index <= #funcs do
		local e = funcs[funcs_index]
		local measure = e.time and time or beat
		if measure < e[1] then break end
		if not e[2] then
			e[3](measure)
		elseif measure < e[1] + e[2] then
			active_funcs:add(e)
		end
		funcs_index = funcs_index + 1
	end
	while true do
		local e = active_funcs:next()
		if not e then break end
		local measure = e.time and time or beat
		if measure < e[1] + e[2] then
			--poptions_logging_target = e.mods
			e[3](measure, poptions)
		else
			if e.mods then
				for pn = 1, max_pn do
					for mod, _ in pairs(e.mods[pn]) do
						touch_mod(mod, pn)
					end
				end
			end
			active_funcs:remove()
		end
	end
end
local seen = 1
local active_nodes = {}
local active_terminators = {}
local propagateAll, propagate
function propagateAll(nodes_to_propagate)
	if nodes_to_propagate then
		for _, nd in ipairs(nodes_to_propagate) do
			propagate(nd)
		end
	end
end
function propagate(nd)
	if nd[9] ~= seen then
		nd[9] = seen
		if nd[8] then
			table.insert(active_terminators, nd)
		else
			propagateAll(nd[4])
			table.insert(active_nodes, nd)
		end
	end
end
function run_nodes()
	for pn = 1, max_pn do
		for mod, _ in pairs(touched_mods[pn]) do
			touch_mod(mod, pn)
			touched_mods[pn][mod] = nil
		end
		seen = seen + 1
		for k in pairs(mods[pn]) do
			propagateAll(node_start[k])
		end
		for _ = 1, #active_nodes do
			table.remove(active_nodes)[6](pn)
		end
		for _ = 1, #active_terminators do
			table.remove(active_terminators)[6](pn)
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
aux 'zoom'
node {
	'zoom', 'zoomx', 'zoomy',
	function(zoom, x, y)
		local m = zoom * 0.01
		return m * x, m * y
	end,
	'zoomx', 'zoomy',
	defer = true,
}
setdefault {
	100, 'zoom',
	100, 'zoomx',
	100, 'zoomy',
	100, 'zoomz',
}
setdefault {400, 'grain'}
local function repeat8(a)
	return a, a, a, a, a, a, a, a
end
for _, a in ipairs {'x', 'y', 'z'} do
	definemod {
		'move' .. a,
		repeat8,
		'move'..a..'0', 'move'..a..'1', 'move'..a..'2', 'move'..a..'3',
		'move'..a..'4', 'move'..a..'5', 'move'..a..'6', 'move'..a..'7',
		defer = true,
	}
end
setdefault {1, 'xmod'}
definemod {
	'xmod', 'cmod',
	function(xmod, cmod, pn)
		if cmod == 0 then
			mod_buffer[pn](string.format('*-1 %fx', xmod))
		else
			mod_buffer[pn](string.format('*-1 %fx,*-1 c%f', xmod, cmod))
		end
	end,
	defer = true,
}
function initMods()
	local disable = false
	if not disable then
		local grain = 2000
	setdefault{grain,'grain',grain,'arrowpathgrain',300,'arrowpathgirth',100,'modtimer'}
	-- mods here
	setdefault{0.5,'xmod',100,'dark',100,'stealth',50,'drunk',100,'tipsy',200,'tipsyspacing',50,'centered',150,'drawsize'}
	ease{4,4,inExpo,0,'dark',0,'stealth',100,'drunk',150,'bouncez',60,'orient',50,'swap'}
	set{15,-100,'movex'}
	set{15.25,100,'movex'}
	set{15.5,100,'movey',0,'movex'}
	ease{15,2,inSine,360,'rotationy'}
	ease{21,1,outElastic,-25,'flip'}
	set{56,200,'drunk',200,'tipsy'}
	ease{56,1,outQuart,50,'drunk',100,'tipsy'}
	set{56,200,'drunk',200,'tipsy'}
	ease{88,2,outSine,50,'drunk',100,'tipsy',10,'swap',0,'flip',0,'movey'}
	set{90,100,'invert',130,'scale'}
	ease{90,1,outSine,0,'invert',100,'scale'}
	set{94,-75,'invert',25,'flip',130,'scale'}
	ease{94,1,outSine,0,'invert',0,'flip',100,'scale'}
	set{98,125,'invert',25,'flip',130,'scale'}
	ease{98,1,outSine,0,'invert',0,'flip',100,'scale'}
	set{102,75,'flip',-125,'invert',130,'scale'}
	ease{102,1,outSine,0,'flip',0,'invert',100,'scale'}
	set{106,75,'flip',75,'invert',130,'scale'}
	ease{106,1,outSine,0,'flip',0,'invert',100,'scale'}
	set{110,100,'flip',-100,'invert',130,'scale'}
	ease{110,1,outSine,0,'flip',0,'invert',100,'scale'}
	set{114,75,'flip',75,'invert',130,'scale'}
	ease{114,1,outSine,0,'flip',0,'invert',100,'scale'}
	set{118,100,'flip',-100,'invert',130,'scale'}
	ease{118,1,outSine,0,'flip',0,'invert',100,'scale'}
	ease{112.5,0.5,linear,200,'movez',plr=1}
	add{114,0.5,linear,200,'movez',plr=1}
	ease{116,0.5,linear,0,'movez',plr=1}
	ease{116,0.5,linear,200,'movez',plr=2}
	add{118,0.5,linear,200,'movez',plr=2}

	-- part1
	set{120,200,'drunk',200,'tipsy',100,'arrowpath',-10,'rotationz'}
	ease{120,1,inSine,30,'drunk',50,'tipsy',0,'arrowpath',0,'rotationz'}
	set{120,0,'rotationy'}
	ease{120,1,outElastic,0,'swap',0,'movez',0,'centered',0.8,'xmod',0,'orient'}
	set{123,-200,'drunk',-200,'tipsy',100,'arrowpath',10,'rotationz'}
	ease{123,1,inSine,30,'drunk',50,'tipsy',0,'arrowpath',0,'rotationz'}
	set{125,200,'drunk',200,'tipsy',100,'arrowpath',-10,'rotationz'}
	ease{125,1,inSine,30,'drunk',50,'tipsy',0,'arrowpath',0,'rotationz'}
	set{127,-200,'drunk',-200,'tipsy',100,'arrowpath',10,'rotationz'}
	ease{127,1,inSine,30,'drunk',50,'tipsy',0,'arrowpath',0,'rotationz'}
	set{129,200,'drunk',200,'tipsy',100,'arrowpath',-10,'rotationz'}
	ease{129,1,inSine,30,'drunk',50,'tipsy',0,'arrowpath',0,'rotationz'}
	set{131,-200,'drunk',-200,'tipsy',100,'arrowpath',10,'rotationz'}
	ease{131,1,inSine,30,'drunk',50,'tipsy',0,'arrowpath',0,'rotationz'}
	set{133,200,'drunk',200,'tipsy',100,'arrowpath',-10,'rotationz'}
	ease{133,1,inSine,30,'drunk',50,'tipsy',0,'arrowpath',0,'rotationz'}
	set{135,-200,'drunk',-200,'tipsy',100,'arrowpath',10,'rotationz'}
	ease{135,1,inSine,30,'drunk',50,'tipsy',0,'arrowpath',0,'rotationz'}
	set{137,200,'drunk',200,'tipsy',100,'arrowpath',-10,'rotationz'}
	ease{137,1,inSine,30,'drunk',50,'tipsy',0,'arrowpath',0,'rotationz'}
	set{139,-200,'drunk',-200,'tipsy',100,'arrowpath',10,'rotationz'}
	ease{139,1,inSine,30,'drunk',50,'tipsy',0,'arrowpath',0,'rotationz'}
	set{141,200,'drunk',200,'tipsy',100,'arrowpath',-10,'rotationz'}
	ease{141,1,inSine,30,'drunk',50,'tipsy',0,'arrowpath',0,'rotationz'}
	set{143,-200,'drunk',-200,'tipsy',100,'arrowpath',10,'rotationz'}
	ease{143,1,inSine,30,'drunk',50,'tipsy',0,'arrowpath',0,'rotationz'}
	set{145,200,'drunk',200,'tipsy',100,'arrowpath',-10,'rotationz'}
	ease{145,1,inSine,30,'drunk',50,'tipsy',0,'arrowpath',0,'rotationz'}
	set{147,-200,'drunk',-200,'tipsy',100,'arrowpath',10,'rotationz'}
	ease{147,1,inSine,30,'drunk',50,'tipsy',0,'arrowpath',0,'rotationz'}
	set{149,200,'drunk',200,'tipsy',100,'arrowpath',-10,'rotationz'}
	ease{149,1,inSine,30,'drunk',50,'tipsy',0,'arrowpath',0,'rotationz'}
	set{151,-200,'drunk',-200,'tipsy',100,'arrowpath',10,'rotationz'}
	ease{151,1,inSine,30,'drunk',50,'tipsy',0,'arrowpath',0,'rotationz'}

	-- centered2 fuck
	-- it's actually not only called centered2, centered67 is also good
	ease{152,168,m='e',linear,2500,'centered2',-2500,'movey'}
	ease{152,2,inCubic,200,'bumpyx',200,'bumpyxperiod',plr=1}
	ease{152,2,inCubic,-200,'bumpyx',200,'bumpyxperiod',plr=2}
	ease{168,174.9,m='e',inExpo,720,'rotationy',400,'bumpy'}
	local a = 1
	for i=168,174 do
		set{i,100*a,'drunkz',100*a,'tipsyz'}
		ease{i,0.5,inSine,0,'drunkz',0,'tipsyz'}
		if i == 1 then
			ease{i,0.5,inCubic,75,'invert',75,'flip'}
		else
			ease{i,0.5,outCubic,0,'invert',0,'flip'}
		end
		a = a * -1
	end
	ease{175,1,outSine,0,'bumpy',0,'bumpyx',0,'bumpyxperiod',0,'tipsyspacing'}
	set{175,0,'rotationy'}
	local function torad(a)
		return math.rad(a) * 100
	end
	ease{176,1,inSine,50,'swap'}
	ease{176,0.3,inBack,torad(360),'confusionxoffset0'}
	ease{176.5,0.3,inBack,torad(360),'confusionxoffset1'}
	ease{177,0.3,inBack,torad(360),'confusionxoffset2'}
	ease{177.5,0.3,inBack,torad(360),'confusionxoffset3'}
	ease{178,0.3,inBack,0,'confusionxoffset0'}
	ease{178.5,0.3,inBack,0,'confusionxoffset1'}
	ease{179,0.3,inBack,0,'confusionxoffset2'}
	ease{179.5,0.3,inBack,0,'confusionxoffset3'}
	set{177,100,'movey',0,'centered2'}
	ease{177,1,outQuad,0,'movey'}
	set{178.5,100,'movey'}
	ease{178.5,1,outQuad,0,'movey'}
	ease{180,1,linear,100,'dark'}
	ease{180,3,outExpo,500,'drunk',100,'tornado'}
	ease{183,1,inSine,0,'drunk',0,'tornado',0,'dark',0,'bouncez'}

	definemod{'blacksphere', function(blacksphere)
		local invert = 50 - 50 * math.cos(blacksphere * math.pi / 180)
		local alternate = 25 * math.sin(blacksphere * math.pi / 180)
		local reverse = -12.5 * math.sin(blacksphere * math.pi / 180)
		return invert, alternate, reverse
		end,'invert', 'alternate', 'reverse'}
	setdefault{0,'blacksphere'}
	ease{184,2,linear,360,'blacksphere'}
	ease{184,1,outElastic,0,'swap',0,'tipsy'}
	set{186,100,'tipsy',100,'drunk',100,'invert'}
	ease{186,1,outSine,0,'drunk',0,'tipsy',0,'invert'}
	ease{187,0.5,linear,50,'stealth',plr=2}
	ease{187,1,outElastic,-600,'movex',plr=1}
	ease{187,0.5,outSine,200,'movez',50,'swap',50,'tipsy',10000,'tipsyspeed',plr=2}
	ease{189,0.5,inSine,0,'movez',0,'swap',0,'tipsyspeed',0,'stealth',plr=2}
	set{190,0,'movex',-200,'movey',plr=1}
	ease{190,1,inSine,0,'movey',plr=1}
	ease{191,0.2,linear,200,'drunk',500,'drunkspeed'}
	ease{192,0.1,linear,0,'drunk',0,'drunkspeed'}
	set{192,0,'blacksphere'}
	ease{192,1,outSine,360,'blacksphere'}
	ease{193,0.5,inBack,100,'reverse',plr=1}
	ease{193.5,0.5,inBack,100,'reverse',plr=2}
	set{194,200,'tipsy'}
	ease{194,1,inExpo,0,'tipsy'}
	set{195,-200,'movex'}
	ease{195,0,inSine,0,'movex'}
	ease{196,0.5,linear,100,'digital'}
	set{196.5,90,'reverse'}
	set{197,80,'reverse'}
	set{197.5,70,'reverse'}
	set{198,40,'reverse'}
	set{198.5,30,'reverse'}
	set{199,20,'reverse'}
	set{199.5,10,'reverse'}
	set{200,0,'reverse'}
	set{200,0,'digital'}

	-- copy
	set{200,0,'blacksphere'}
	ease{200,1,linear,360,'blacksphere'}
	ease{200,1,outElastic,0,'swap',0,'tipsy'}
	set{202,100,'tipsy',100,'drunk',100,'invert'}
	ease{202,1,outSine,0,'drunk',0,'tipsy',0,'invert'}
	ease{203,0.5,linear,50,'stealth',plr=1}
	ease{203,1,outElastic,600,'movex',plr=2}
	ease{203,0.5,outSine,200,'movez',50,'swap',50,'tipsy',10000,'tipsyspeed',plr=1}
	ease{205,0.5,inSine,0,'movez',0,'swap',0,'tipsyspeed',0,'stealth',plr=1}
	set{206,0,'movex',-200,'movey',plr=2}
	ease{206,1,inSine,0,'movey',plr=2}
	ease{207,0.2,linear,200,'drunk',500,'drunkspeed'}
	ease{208,0.1,linear,0,'drunk',0,'drunkspeed'}
	set{208,0,'blacksphere'}
	ease{208,1,outSine,360,'blacksphere'}
	ease{209,0.5,inBack,100,'reverse',plr=2}
	ease{209.5,0.5,inBack,100,'reverse',plr=1}
	set{210,200,'tipsy'}
	ease{210,1,inExpo,0,'tipsy'}
	set{211,-200,'movex'}
	ease{211,0,inSine,0,'movex'}
	ease{212,0.5,linear,60,'digital'}
	set{212.5,90,'reverse'}
	set{213,80,'reverse'}
	set{213.5,70,'reverse'}
	set{214,40,'reverse'}
	set{214.5,30,'reverse'}
	set{215,20,'reverse'}
	set{215.5,10,'reverse'}
	set{216,0,'reverse'}
	set{216,0,'digital'}


	ease{216,0.5,inSine,-50,'skewx'}
	ease{216.5,0.5,inSine,50,'skewx'}
	ease{217,1,inSine,0,'skewx'}
	set{218,100,'zigzag',200,'movex'}
	ease{218,1,inSine,0,'zigzag',0,'movex'}
	set{219,100,'drunk',100,'tipsyz'}
	ease{219,1,inSine,0,'drunk',0,'tipsyz'}
	set{219.5,60,'digital'}
	ease{220,1,outCirc,200,'drunk'}
	ease{221,1,outCirc,0,'drunk'}
	set{222,100,'drunk',100,'tipsy',0,'digital'}
	ease{222,1,inSine,0,'drunk',0,'tipsy'}
	set{223,-100,'drunk',-100,'tipsy'}
	ease{223,1,inSine,0,'drunk',0,'tipsy'}
	set{224,100,'bouncey'}
	set{226,100,'drunk',100,'tipsy',-200,'movez',100,'reverse',0,'movex',0,'bouncey'}
	set{224,-100,'movex'}{224.5,-200,'movex'}{225,100,'movex'}{225.5,200,'movex'}
	ease{226,1,inExpo,0,'drunk',0,'tipsy',0,'movez'}
	ease{227,0.5,linear,100,'flip',30,'confusionoffset'}
	ease{227.5,0.5,linear,-20,'flip',-30,'confusionoffset'}
	ease{228,0.5,inSine,0,'confusionoffset'}
	ease{228,0.5,outCirc,-100,'movey'}
	ease{228.5,0.5,inSine,0,'movey'}
	ease{229,0.5,outCirc,-100,'movey'}
	ease{229.5,0.5,inSine,0,'movey'}
	ease{230,0.5,outCirc,-100,'movey'}
	ease{230.5,0.5,inSine,0,'movey'}
	set{231,50,'reverse'}
	set{231.5,0,'reverse'}
	ease{232,0.5,linear,100,'orient',1000,'bumpyxperiod',1000,'bumpyperiod',600,'bumpy',0,'flip',50,'swap'}
	ease{232,0.5,linear,400,'bumpyx',75,'stealth',plr=1}
	ease{232,0.5,linear,-400,'bumpyx',plr=2}
	ease{232,248,m='e',linear,2000,'centered2',-2000,'movey'}
	set{234,100,'drunk',100,'tipsy'}
	ease{234,1,outSine,0,'drunk',0,'tipsy'}
	set{238,100,'drunk',100,'tipsy'}
	ease{238,1,outSine,0,'drunk',0,'tipsy'}
	set{242,100,'drunk',100,'tipsy'}
	ease{242,1,outSine,0,'drunk',0,'tipsy'}
	set{246,100,'drunk',100,'tipsy'}
	ease{246,1,outSine,0,'drunk',0,'tipsy'}
	ease{248,1,linear,0,'orient',0,'bumpyx',0,'bumpyxperiod',0,'bumpyperiod',0,'bumpy',200,'drunk',0,'swap',0,'stealth'}
	set{249,0,'centered2',0,'movey'}
	ease{248,1,linear,0,'blacksphere'}
	set{250,150,'scale',200,'tipsy'}
	ease{250,1,inSine,0,'drunk',100,'scale',0,'tipsy'}
	ease{250,0.5,outCirc,-10,'rotationy',-30,'rotationz'}
	ease{250.5,0.5,inSine,0,'rotationy',0,'rotationz'}
	ease{251,0.5,outSine,500,'bumpy',200,'bumpyperiod'}
	ease{251.5,.5,inBack,0,'bumpy',0,'bumpyperiod'}
	ease{252,1,linear,360,'blacksphere'}
	set{254,150,'scale',-200,'tipsy'}
	ease{254,1,inSine,0,'drunk',100,'scale',0,'tipsy'}
	ease{254,0.5,outCirc,10,'rotationy',30,'rotationz'}
	ease{254.5,0.5,inSine,0,'rotationy',0,'rotationz'}
	ease{255,0.5,outSine,500,'bumpy',200,'bumpyperiod'}
	ease{255.5,.5,inBack,0,'bumpy',0,'bumpyperiod'}
	ease{256,1,linear,0,'blacksphere'}{256,.5,inSine,-50,'skewx'}{256.5,.5,inSine,0,'skewx'}
	ease{257,1,linear,360,'rotationy'}
	set{258,100,'drunk',-150,'movez',100,'tipsy',100,'bumpy'}
	ease{258,1,inSine,0,'movez',0,'drunk',0,'tipsy',0,'bumpy'}
	ease{259,1,linear,360,'blacksphere'}
	set{261,0,'rotationy',0,'movex'}
	ease{261,0.5,outCirc,-100,'movey',-30,'rotationz'}
	ease{261.5,0.5,inSine,0,'movey',0,'rotationz'}
	ease{262,0.5,outCirc,-100,'movey',30,'rotationz'}
	ease{262.5,0.5,inSine,0,'movey',0,'rotationz'}
	ease{263,0.5,outCirc,-100,'movey',-30,'rotationz'}
	ease{263.5,0.5,inSine,0,'movey',0,'rotationz'}

	ease{248+16,1,linear,0,'blacksphere'}
	set{250+16,150,'scale',200,'tipsy'}
	ease{250+16,1,inSine,0,'drunk',100,'scale',0,'tipsy'}
	ease{250+16,0.5,outCirc,-10,'rotationy',-30,'rotationz'}
	ease{250.5+16,0.5,inSine,0,'rotationy',0,'rotationz'}
	ease{251+16,0.5,outSine,500,'bumpy',200,'bumpyperiod'}
	ease{251.5+16,.5,inBack,0,'bumpy',0,'bumpyperiod'}
	ease{252+16,1,linear,360,'blacksphere'}
	set{254+16,150,'scale',-200,'tipsy'}
	ease{254+16,1,inSine,0,'drunk',100,'scale',0,'tipsy'}
	ease{254+16,0.5,outCirc,10,'rotationy',30,'rotationz'}
	ease{254.5+16,0.5,inSine,0,'rotationy',0,'rotationz'}
	ease{255+16,0.5,outSine,500,'bumpy',200,'bumpyperiod'}
	ease{255.5+16,.5,inBack,0,'bumpy',0,'bumpyperiod'}
	ease{256+16,1,linear,0,'blacksphere'}{256,.5,inSine,-50,'skewx'}{256.5,.5,inSine,0,'skewx'}
	ease{257+16,1,linear,360,'rotationy'}
	set{258+16,100,'drunk',-150,'movez',100,'tipsy',100,'bumpy'}
	ease{258+16,1,inSine,0,'movez',0,'drunk',0,'tipsy',0,'bumpy'}
	ease{259+16,1,linear,360,'blacksphere'}
	set{261+16,0,'rotationy',0,'movex'}
	ease{261+16,0.5,outCirc,-100,'movey',-30,'rotationz'}
	ease{261.5+16,0.5,inSine,0,'movey',0,'rotationz'}
	ease{262+16,0.5,outCirc,-100,'movey',30,'rotationz'}
	ease{262.5+16,0.5,inSine,0,'movey',0,'rotationz'}
	ease{263+16,0.5,outCirc,-100,'movey',-30,'rotationz'}
	ease{263.5+16,0.5,inSine,0,'movey',0,'rotationz'}
	ease{280,1,linear,0,'blacksphere'}
	set{281,100,'drunk',100,'tipsy',-30,'confusionxoffset',-10,'rotationz'}
	ease{281,.5,inSine,0,'drunk',0,'tipsy',0,'confusionxoffset',0,'rotationz'}
	set{281.5,-100,'drunk',-100,'tipsy',30,'confusionxoffset',10,'rotationz'}
	ease{281.5,.5,inSine,0,'drunk',0,'tipsy',0,'confusionxoffset',0,'rotationz'}
	set{282,200,'drunk',-100,'movex'}
	ease{282,1,inCirc,0,'drunk',0,'movex'}
	ease{283,0.5,linear,200,'tipsy'}
	ease{283.5,0.5,linear,0,'tipsy'}
	ease{284,1,linear,100,'beat'}
	set{286,100,'movex',0,'beat'}
	ease{286,1,inCirc,0,'movex'}
	ease{287,1,linear,360,'rotationy'}
	set{288,-30,'rotationz',0,'rotationy'}
	ease{288,1,linear,360,'blacksphere',0,'rotationz'}
	definemod{'rotx','roty','rotz',function(xDegrees, yDegrees, zDegrees, plr)
    local function mindf_reverseRotation(angleX, angleY, angleZ)
        local sinX = math.sin(angleX);
        local cosX = math.cos(angleX);
        local sinY = math.sin(angleY);
        local cosY = math.cos(angleY);
        local sinZ = math.sin(angleZ);
        local cosZ = math.cos(angleZ);
        return { math.atan2(-cosX*sinY*sinZ-sinX*cosZ,cosX*cosY),
                math.asin(-cosX*sinY*cosZ+sinX*sinZ),
                math.atan2(-sinX*sinY*cosZ-cosX*sinZ,cosY*cosZ) }
    end
    local DEG_TO_RAD = math.pi / 180
    local angles = mindf_reverseRotation(xDegrees * DEG_TO_RAD, yDegrees * DEG_TO_RAD, zDegrees * DEG_TO_RAD)
    local rotationx,rotationy,rotationz=
        xDegrees,
        yDegrees,
        zDegrees
    local confusionxoffset,confusionyoffset,confusionzoffset=
        (angles[1]*100),
        (angles[2]*100),
        (angles[3]*100)

    return rotationx,rotationy,rotationz,confusionxoffset,confusionyoffset,confusionzoffset
	end,
	'rotationx','rotationy','rotationz','confusionxoffset','confusionyoffset','confusionzoffset'
	}
	setdefault{0,'rotx',0,'roty',0,'rotz'}
	set{290,-20,'rotz',-100,'noteskewx'}
	ease{290,.75,inSine,0,'rotz',0,'noteskewx'}
	set{290.75,20,'rotz',100,'noteskewx'}
	ease{290.75,.75,inSine,0,'rotz',0,'noteskewx'}
	set{291,-20,'rotz',-100,'noteskewx'}
	ease{291,.5,inSine,0,'rotz',0,'noteskewx'}
	ease{292,0.5,linear,200,'drunk'}
	ease{292,1,linear,2000,'drunkspeed'}
	ease{293,1,outCirc,0,'drunk',0,'drunkspeed'}
	set{294,100,'reverse0'}
	set{294.5,100,'reverse1'}
	set{295,100,'reverse2'}
	set{295.5,100,'reverse3'}
	ease{296,0.5,linear,100,'orient',1000,'bumpyxperiod',1000,'bumpyperiod',600,'bumpy',50,'swap'}
	for col=0,3 do
	ease{296,0.5,linear,0,'reverse'..col}
	end
	ease{296,0.5,linear,400,'bumpyx',75,'stealth',plr=1}
	ease{296,0.5,linear,-400,'bumpyx',plr=2}
	ease{296,312,m='e',linear,2000,'centered2',-2000,'movey'}
	ease{312,1,linear,0,'orient',0,'bumpyx',0,'bumpyxperiod',0,'bumpyperiod',0,'bumpy',0,'swap',100,'stealth',100,'dark'}
	set{312,0,'centered2',0,'movey'}
	set{298,100,'drunk',100,'tipsy'}
	ease{298,1,outSine,0,'drunk',0,'tipsy'}
	set{302,100,'drunk',100,'tipsy'}
	ease{302,1,outSine,0,'drunk',0,'tipsy'}
	set{306,100,'drunk',100,'tipsy'}
	ease{306,1,outSine,0,'drunk',0,'tipsy'}
	set{310,100,'drunk',100,'tipsy'}
	ease{310,1,outSine,0,'drunk',0,'tipsy'}
	set{312,-1000,'movez',50,'swap'}
	ease{312,1,linear,0,'stealth',0,'dark'}
	ease{312,8,inExpo,0,'movez'}
	ease{313,0.5,outElastic,-20,'flip'}
	ease{315,0.5,outCirc,-100,'movey',-30,'rotationz',-30,'flip'}
	ease{315.5+16,0.5,inSine,0,'movey',0,'rotationz',0,'flip'}
	ease{316,0.5,outCirc,-100,'movey',30,'rotationz',-30,'flip'}
	ease{316.5,0.5,inSine,0,'movey',0,'rotationz',0,'flip'}
	ease{317,0.5,outCirc,-100,'movey',-30,'rotationz',-30,'flip'}
	ease{317.5,0.5,inSine,0,'movey',0,'rotationz',0,'flip'}
	ease{318,0.5,outCirc,-100,'movey',30,'rotationz',-30,'flip'}
	ease{318.5,0.5,inSine,0,'movey',0,'rotationz',0,'flip'}
	ease{319,0.5,outCirc,-100,'movey',-30,'rotationz',-30,'flip'}
	ease{319.5,0.5,inSine,0,'movey',0,'rotationz',0,'flip'}
	ease{302,1,outSine,0,'drunk',0,'tipsy'}
	set{320,100,'drunk',100,'tipsyx',100,'drunky'}
	ease{320,1,inExpo,0,'drunk',0,'tipsyx',0,'drunky'}
	set{321,100,'drunk',100,'tipsyx',100,'drunky'}
	ease{321,1,inExpo,0,'drunk',0,'tipsyx',0,'drunky'}
	set{322,100,'drunk',100,'tipsyx',100,'drunky'}
	ease{322,1,inExpo,0,'drunk',0,'tipsyx',0,'drunky'}
	set{323,100,'drunk',100,'tipsyx',100,'drunky'}
	ease{323,1,inExpo,0,'drunk',0,'tipsyx',0,'drunky'}
	ease{320,1,linear,100,'tipsyz'}
	ease{324,0.5,inSine,-500,'drunk',-100,'tornado'}
	ease{324.5,1,outSine,0,'drunk',0,'tornado'}
	set{325.5,-20,'flip'}
	ease{325.5,.25,inSine,0,'flip'}
	set{325.75,-20,'flip'}
	ease{325.75,.25,inSine,0,'flip'}
	set{326,-20,'flip'}
	ease{326,.5,inSine,0,'flip'}
	set{326.5,-20,'flip'}
	ease{326.5,.5,inSine,0,'flip'}
	set{327,-20,'flip'}
	ease{327,.5,inSine,0,'flip'}
	ease{327,1,inSine,0,'swap',0,'tipsyz'}

	local function swap(t)
		local beat, len, curve, which = t[1], t[2], t[3], t[4]
		t.width = t.width or 1
		local s = {
			normal = {0,0},
			invert = {0,100},
			flip = {100,0},
			ludr = {25,-75},
			drlu = {25,125},
			rdul = {75,75},
			ulrd = {75,-125},
			urld = {100,-100},
		}
		ease {beat, len, curve,
			(s[tostring(which)][1]*t.width) + (50 - t.width * 50), 'flip',
			(s[tostring(which)][2]*t.width), 'invert'
		, plr = t.plr}
	end

	set{328,100,'drunk',100,'tipsyx',200,'tipsyz',60,'pulse'}
	ease{328,1,inExpo,0,'drunk',0,'tipsyx',0,'tipsyz',0,'pulse'}
	swap{329,0.1,linear,'urld'}
	swap{329.5,0.1,linear,'ludr'}
	swap{330,0.1,linear,'normal'}
	set{329,10,'rotationy',20,'rotationz'}
	ease{329,1,inSine,0,'rotationy',0,'rotationz'}
	set{330,100,'drunk',100,'tipsy'}
	ease{330,1,outSine,0,'drunk',0,'tipsy'}
	set{329,100,'stealthr',-50,'noteskewx'}
	set{329.5,100,'stealthg',-100,'noteskewx'}
	set{330,0,'stealthr',0,'stealthg',0,'noteskewx'}
	set{331,100,'drunk',100,'tipsy'}
	ease{331,.5,outSine,0,'drunk',0,'tipsy'}
	swap{331.5,0.1,linear,'drlu'}
	swap{332,0.1,linear,'urld'}
	swap{332.5,0.1,linear,'ludr'}
	swap{333,1,inExpo,'normal'}
	set{331.5,100,'stealthr',50,'noteskewx'}
	set{332,100,'stealthg',100,'noteskewx'}
	set{332.5,50,'stealth',100,'stealthgr',150,'noteskewx'}
	set{333,0,'stealth',0,'stealthgr',0,'stealthr',0,'stealthg',200,'noteskewx'}
	ease{333,1,inExpo,0,'noteskewx'}
	ease{334,0.5,inCubic,100,'drunk',100,'tipsy',300,'drunkspeed',300,'tipsyspeed'}
	ease{335.5,0.5,inCubic,0,'drunk',0,'tipsy',0,'drunkspeed',0,'tipsyspeed'}

	-- copy 2
	set{328+8,100,'drunk',100,'tipsyx',200,'tipsyz',60,'pulse'}
	ease{328+8,1,inExpo,0,'drunk',0,'tipsyx',0,'tipsyz',0,'pulse'}
	swap{329+8,0.1,linear,'urld'}
	swap{329.5+8,0.1,linear,'ludr'}
	swap{330+8,0.1,linear,'normal'}
	set{329+8,10,'rotationy',20,'rotationz'}
	ease{329+8,1,inSine,0,'rotationy',0,'rotationz'}
	set{330+8,100,'drunk',100,'tipsy'}
	ease{330+8,1,outSine,0,'drunk',0,'tipsy'}
	set{329+8,100,'stealthr',50,'noteskewx'}
	set{329.5+8,100,'stealthg',100,'noteskewx'}
	set{330+8,0,'stealthr',0,'stealthg',0,'noteskewx'}
	set{331+8,100,'drunk',100,'tipsy'}
	ease{331+8,.5,outSine,0,'drunk',0,'tipsy'}
	swap{331.5+8,0.1,linear,'drlu'}
	swap{332+8,0.1,linear,'urld'}
	swap{332.5+8,0.1,linear,'ludr'}
	swap{333+8,1,inExpo,'normal'}
	set{331.5+8,100,'stealthr',-50,'noteskewx'}
	set{332+8,100,'stealthg',-100,'noteskewx'}
	set{332.5+8,50,'stealth',100,'stealthgr',-150,'noteskewx'}
	set{333+8,0,'stealth',0,'stealthgr',0,'stealthr',0,'stealthg',-200,'noteskewx'}
	ease{333+8,1,inExpo,0,'noteskewx'}
	ease{334+8,0.5,inCubic,100,'drunk',100,'tipsy',300,'drunkspeed',300,'tipsyspeed'}
	ease{335.5+8,0.5,inCubic,0,'drunk',0,'tipsy',0,'drunkspeed',0,'tipsyspeed'}

	set{344,0,'blacksphere'}
	ease{344,1,linear,360,'blacksphere'}
	set{345,-5,'rotz'}
	ease{345,0.5,inCubic,0,'rotz'}
	set{345.5,5,'rotz'}
	ease{345.5,0.5,inCubic,0,'rotz'}
	set{346,100,'drunk',100,'tipsy'}
	ease{346,1,outSine,0,'drunk',0,'tipsy'}
	ease{347,1,linear,360,'roty'}
	ease{348,1,inSine,100,'swap'}
	ease{349,1,inSine,0,'swap'}
	ease{350,1,inSine,100,'swap'}
	set{351,200,'drunk',200,'tipsy',-20,'flip'}
	ease{351,1,outSine,0,'drunk',0,'tipsy',0,'flip'}
	set{352,-100,'movex'}
	ease{352,1.5,inCubic,100,'drunkz',100,'tipsyx',700,'bumpy',0,'movex',0,'swap',plr=1}
	ease{352,1.5,inCubic,100,'drunk',100,'tipsy',300,'bouncez',0,'movex',0,'swap',plr=2}
	set{352,100,'movex'}
	ease{352,0.1,inCubic,0,'drunkz',0,'tipsyx',0,'bumpy',plr=1}
	ease{352,0.1,inCubic,0,'drunk',0,'tipsy',0,'bouncez',plr=2}
	ease{352,1.5,inCubic,100,'drunkz',100,'tipsyx',500,'bumpy',200,'bumpyperiod',0,'movex',100,'swap',plr=2}
	ease{352,1.5,inCubic,100,'drunk',100,'tipsy',300,'bouncez',0,'movex',100,'swap',plr=1}
	set{355,100,'cubicx',-100,'movey',100,'tipsy'}
	ease{355,1,inCubic,0,'cubicx',0,'movey',0,'tipsy'}
	set{356,-100,'movex',100,'bouncey'}
	ease{356,1,inCirc,0,'movex',0,'bouncey',0,'drunkz',0,'drunk',0,'tipsyx',0,'tipsy',0,'bumpy',0,'bouncez',0,'swap'}
	ease{356,1,inCirc,200,'movez',plr=2}
	set{357,100,'movex',100,'bouncey'}
	ease{357,1,inCirc,0,'movex',0,'bouncey',100,'swap'}
	ease{357,1,inCirc,200,'movez',plr=1}
	set{358,50,'pulse',100,'drunk',100,'tipsy',-200,'movez'}
	ease{358,2,outSine,0,'movez',0,'drunk',0,'tipsy',0,'pulse'}

	-- copy 3
	set{328+32,100,'drunk',100,'tipsyx',200,'tipsyz',60,'pulse'}
	ease{328+32,1,inExpo,0,'drunk',0,'tipsyx',0,'tipsyz',0,'pulse'}
	swap{329+32,0.1,linear,'urld'}
	swap{329.5+32,0.1,linear,'ludr'}
	swap{330+32,0.1,linear,'normal'}
	set{329+32,10,'rotationy',20,'rotationz'}
	ease{329+32,1,inSine,0,'rotationy',0,'rotationz'}
	set{330+32,100,'drunk',100,'tipsy'}
	ease{330+32,1,outSine,0,'drunk',0,'tipsy'}
	set{329+32,100,'stealthr',-50,'noteskewx'}
	set{329.5+32,100,'stealthg',-100,'noteskewx'}
	set{330+32,0,'stealthr',0,'stealthg',0,'noteskewx'}
	set{331+32,100,'drunk',100,'tipsy'}
	ease{331+32,.5,outSine,0,'drunk',0,'tipsy'}
	swap{331.5+32,0.1,linear,'drlu'}
	swap{332+32,0.1,linear,'urld'}
	swap{332.5+32,0.1,linear,'ludr'}
	swap{333+32,1,inExpo,'normal'}
	set{331.5+32,100,'stealthr',50,'noteskewx'}
	set{332+32,100,'stealthg',100,'noteskewx'}
	set{332.5+32,50,'stealth',100,'stealthgr',150,'noteskewx'}
	set{333+32,0,'stealth',0,'stealthgr',0,'stealthr',0,'stealthg',200,'noteskewx'}
	ease{333+32,1,inExpo,0,'noteskewx'}
	ease{334+32,0.5,inCubic,100,'drunk',100,'tipsy',300,'drunkspeed',300,'tipsyspeed'}
	ease{335.5+32,0.5,inCubic,0,'drunk',0,'tipsy',0,'drunkspeed',0,'tipsyspeed'}

	-- copy 4
	set{328+8+32,100,'drunk',100,'tipsyx',200,'tipsyz',60,'pulse'}
	ease{328+8+32,1,inExpo,0,'drunk',0,'tipsyx',0,'tipsyz',0,'pulse'}
	swap{329+8+32,0.1,linear,'urld'}
	swap{329.5+8+32,0.1,linear,'ludr'}
	swap{330+8+32,0.1,linear,'normal'}
	set{329+8+32,10,'rotationy',20,'rotationz'}
	ease{329+8+32,1,inSine,0,'rotationy',0,'rotationz'}
	set{330+8+32,100,'drunk',100,'tipsy'}
	ease{330+8+32,1,outSine,0,'drunk',0,'tipsy'}
	set{329+8+32,100,'stealthr',50,'noteskewx'}
	set{329.5+8+32,100,'stealthg',100,'noteskewx'}
	set{330+8+32,0,'stealthr',0,'stealthg',0,'noteskewx'}
	set{331+8+32,100,'drunk',100,'tipsy'}
	ease{331+8+32,.5,outSine,0,'drunk',0,'tipsy'}
	swap{331.5+8+32,0.1,linear,'drlu'}
	swap{332+8+32,0.1,linear,'urld'}
	swap{332.5+8+32,0.1,linear,'ludr'}
	swap{333+8+32,1,inExpo,'normal'}
	set{331.5+8+32,100,'stealthr',-50,'noteskewx'}
	set{332+8+32,100,'stealthg',-100,'noteskewx'}
	set{332.5+8+32,50,'stealth',100,'stealthgr',-150,'noteskewx'}
	set{333+8+32,0,'stealth',0,'stealthgr',0,'stealthr',0,'stealthg',-200,'noteskewx'}
	ease{333+8+32,1,inExpo,0,'noteskewx'}
	ease{334+8+32,0.5,inCubic,100,'drunk',100,'tipsy',300,'drunkspeed',300,'tipsyspeed'}
	ease{335.5+8+32,0.5,inCubic,0,'drunk',0,'tipsy',0,'drunkspeed',0,'tipsyspeed'}

	set{344+32,0,'blacksphere'}
	ease{344+32,1,linear,360,'blacksphere'}
	set{345+32,-5,'rotz'}
	ease{345+32,0.5,inCubic,0,'rotz'}
	set{345.5+32,5,'rotz'}
	ease{345.5+32,0.5,inCubic,0,'rotz'}
	set{346+32,100,'drunk',100,'tipsy'}
	ease{346+32,1,outSine,0,'drunk',0,'tipsy'}
	ease{347+32,1,linear,360,'roty'}
	ease{380,.75,linear,180,'rotationx'}
	ease{381,1,linear,360,'rotationx'}
	set{382,100,'drunk',100,'tipsy'}
	ease{382,0.5,outSine,0,'drunk',0,'tipsy'}
	set{382,100,'reverse0',100,'reverse1',plr=1}
	set{382.5,100,'reverse2',100,'reverse3',plr=1}
	set{383,100,'reverse0',100,'reverse1',plr=2}
	set{383.5,100,'reverse2',100,'reverse3',plr=2}
	ease{384,4,linear,460,'centered2'}
	ease{388,4,linear,0,'centered2',0,'reverse0',0,'reverse1',0,'reverse2',0,'reverse3',0,'swap'}

	local function sm2(tab)
		local b,len,eas,amt,mods,intime = tab[1],tab[2],tab[3],tab[4],tab[5],tab.intime
		if not intime then intime = .1 end
		if intime <= 0 then intime = .001 end
		ease{b-intime,intime,linear,amt,mods,plr=tab.pn}
		ease{b,len-intime,eas,0,mods,plr=tab.pn}
	end
	sm2{392,1.5,outCubic,200,'drunk'}
	sm2{392,1.5,outCubic,100,'brake'}
	ease{392,1.5,inOutCubic,100,'reverse'}
	sm2{393.5,1.5,outCubic,200,'drunk'}
	sm2{393.5,1.5,outCubic,100,'brake'}
	ease{393.5,1.5,inOutCubic,0,'reverse'}
	sm2{395,1,outCubic,200,'drunk'}
	sm2{395,1,outCubic,100,'brake'}
	ease{395,1,linear,100,'reverse'}
	ease{395,2,linear,200,'drunk'}
	ease{397,2,linear,0,'drunk'}
	ease{395,4,inOutCubic,0,'reverse'}
	set{399,100,'drunk',100,'tipsy'}
	ease{399,1,outSine,0,'drunk',0,'tipsy',0,'wave'}
	sm2{392+8,2,outCubic,200,'drunk'}
	sm2{392+8,2,outCubic,100,'brake'}
	ease{392+8,1.5,inOutCubic,100,'reverse'}
	sm2{402,1,outCubic,200,'drunk'}
	sm2{402,1,outCubic,100,'brake'}
	ease{402,1,inOutCubic,0,'reverse'}
	sm2{395+8,1,outCubic,200,'drunk'}
	sm2{395+8,1,outCubic,100,'brake'}
	ease{395+8,1,inOutCubic,100,'reverse'}
	ease{404,2,inOutCubic,0,'reverse',100,'wave'}
	set{404,100,'drunk',100,'tipsy',-30,'roty'}
	ease{404,1.5,outSine,0,'drunk',0,'tipsy',0,'roty'}
	set{404.5,100,'drunk',100,'tipsy'}
	ease{404.5,1.5,outSine,0,'drunk',0,'tipsy'}
	set{405.5,30,'roty'}
	ease{405.5,1.5,outSine,0,'roty'}
	set{407,-30,'roty'}
	ease{407,1,outSine,0,'roty'}
	set{407,100,'drunk',100,'tipsy'}
	ease{407,1,outSine,0,'drunk',0,'tipsy',0,'wave'}
	func{408,16,function(beat,poptions)
			poptions[1].x = 35 * math.cos(math.pi * beat)
			poptions[1].y = -40 * math.abs(math.sin(math.pi * beat))
			poptions[1].z = -100 * math.abs(math.sin(math.pi * beat))
			poptions[2].x = 35 * math.cos(math.pi * beat)
			poptions[2].y = -40 * math.abs(math.sin(math.pi * beat))
			poptions[2].z = -100 * math.abs(math.sin(math.pi * beat))
	end}
	ease{408,1,inSine,100,'reverse',plr=2}
	ease{408,1,inSine,100,'swap',100,'beat'}
	ease{416,1,inSine,0,'reverse',plr=2}
	ease{416,1,inSine,100,'reverse',plr=1}
	ease{416,1,inSine,0,'swap'}
	ease{424,1,inOutCubic,0,'reverse',0,'beat',-100,'movez',-32,'roty'}
	ease{425,1,inOutCubic,12,'roty'}{426,1,inOutCubic,56,'roty'}{427,1,inOutCubic,-15,'roty'}
	ease{428,1,inOutCubic,-200,'movez',32,'roty'}{429,1,inOutCubic,-24,'roty'}{430,1,inOutCubic,30,'roty'}{431,1,inOutCubic,40,'roty'}
	ease{432,1,inOutCubic,-300,'movez',25,'roty'}{433,1,inOutCubic,-20,'roty'}{434,1,inOutCubic,-50,'roty'}ease{435,1,inOutCubic,12,'roty'}
	ease{428,1,outCubic,100,'swap'}
	ease{432,1,outCubic,0,'swap'}
	ease{436,1,outCubic,0,'movez',100,'drunk',100,'tipsy',100,'beat',0,'roty'}
	set{436,-100,'movex'}
	ease{436,1,outQuad,0,'movex'}
	set{437,100,'movex'}
	ease{437,1,outQuad,0,'movex'}
	ease{438,2,linear,360,'rotz'}

	set{440,0,'rotz',200,'square',500,'digital',600,'zigzag',0,'beat'}
	ease{440,1,inCubic,0,'square',0,'digital',0,'zigzag',50,'swap'}
	set{456,200,'square',500,'digital',600,'zigzag',0,'beat'}
	ease{456,1,inCubic,0,'square',0,'digital',0,'zigzag',50,'swap'}
	ease{440,1,linear,100,'dark',100,'stealth',plr=1}
	ease{441,504,m='e',linear,8000,'centered2',-8000,'movey'}
	ease{441,1,linear,200,'bumpyx',1000,'bumpyxperiod'}
	local mult = 1
	for i=441,504,4 do
		set{i+1,-200,'movex',200,'drunk',200,'tipsy',200,'drunkz',200,'tipsyz'}
		ease{i+1,1,outQuart,0,'movex',0,'drunk',0,'tipsy',0,'drunkz',0,'tipsyz'}
		set{i+3,200,'movex',-200,'drunk',-200,'tipsy',-200,'drunkz',-200,'tipsyz'}
		ease{i+3,1,outQuart,0,'movex',0,'drunk',0,'tipsy',0,'drunkz',0,'tipsyz'}
		ease{i,1,inSine,torad(360),'confusionoffset',-30,'roty'}
		ease{i+2,1,inSine,0,'confusionoffset',30,'roty'}
		ease{i,0.5,outSine,20,'flip'}
		ease{i+0.5,0.5,inSine,0,'flip'}
		ease{i+2,0.5,outSine,20,'flip'}
		ease{i+2.5,0.5,inSine,0,'flip'}
		add{i,0.5,outCubic,200,'bumpyxoffset'}
		add{i,0.5,outCubic,200,'bumpyxoffset'}
		add{i,0.5,outCubic,200,'bumpyxoffset'}
		add{i,0.5,outCubic,200,'bumpyxoffset'}
		set{i,200,'drunk',200,'tipsyz'}
		ease{i,1,outQuart,0,'drunk',0,'tipsyz'}
		set{i+2,200,'drunk',200,'tipsyz'}
		ease{i+2,1,outQuart,0,'drunk',0,'tipsyz'}
		mult = mult * -1
	end
	ease{456,1,linear,0,'bouncey'}
	ease{504,1,linear,0,'tipsy',0,'drunkz',0,'tipsyz',0,'confusionoffset',0,'roty',0,'bumpyx',0,'movex',0,'flip',0,'bumpyy',0,'x'}
	set{504,0,'centered2',0,'movey'}
	ease{504,1,linear,100,'drunk',100,'twirl'}
	ease{508,510,m='e',linear,500,'drunkspeed'}
	set{505,0,'bumpyxoffset',0,'bumpyxperiod'}
	swap{511,0.1,linear,'ludr'}
	swap{511.25,0.1,linear,'drlu'}
	swap{511.5,0.1,linear,'ulrd'}
	swap{511.75,0.1,linear,'rdul'}
	swap{512,0.1,linear,'normal'}
	ease{512,1,linear,0,'twirl'}
	local mult = 1
	for i=512,535,4 do
		set{i+1,-200,'movex',200,'drunk',200,'tipsy',200,'drunkz',200,'tipsyz'}
		ease{i+1,1,outQuart,0,'movex',0,'drunk',0,'tipsy',0,'drunkz',0,'tipsyz'}
		set{i+3,200,'movex',-200,'drunk',-200,'tipsy',-200,'drunkz',-200,'tipsyz'}
		ease{i+3,1,outQuart,0,'movex',0,'drunk',0,'tipsy',0,'drunkz',0,'tipsyz'}
		ease{i,1,inSine,torad(360),'confusionoffset',-30,'roty'}
		ease{i+2,1,inSine,0,'confusionoffset',30,'roty'}
		ease{i,0.5,outSine,20,'flip'}
		ease{i+0.5,0.5,inSine,0,'flip'}
		ease{i,1,outCubic,200 * mult,'x'}
		set{i,200,'drunk',200,'tipsyz'}
		ease{i,1,outQuart,0,'drunk',0,'tipsyz'}
		set{i+2,200,'drunk',200,'tipsyz'}
		ease{i+2,1,outQuart,0,'drunk',0,'tipsyz'}
		mult = mult*-1
	end
	ease{535,1,linear,0,'tipsy',0,'drunkz',0,'tipsyz',0,'confusionoffset',0,'roty',0,'bumpyx',0,'movex',0,'flip',0,'x'}
	set{516,-30,'rotz'}
	ease{516,0.75,outCubic,0,'rotz'}
	set{517.25,30,'rotz'}
	ease{517.25,0.75,outCubic,0,'rotz'}
	set{518,-30,'rotz'}
	ease{518,1,outCubic,0,'rotz'}
	set{519,30,'rotz'}
	ease{519,1,outCubic,0,'rotz'}
	local a = 444.25
	set{a,20,'rotationz'}
	set{a+.25,-20,'rotationz'}
	set{a+.5,20,'rotationz'}
	set{a+.75,0,'rotationz'}
	local a = 445.25
	set{a,-20,'rotationz'}
	set{a+.25,20,'rotationz'}
	set{a+.5,-20,'rotationz'}
	set{a+.75,20,'rotationz'}
	local a = 446.25
	set{a,-20,'rotationz'}
	set{a+.25,20,'rotationz'}
	set{447,20,'rotationz',170,'zoom'}
	ease{447,0.5,outQuad,0,'rotationz',0,'rotationz',100,'zoom'}
	local a = 450
	set{a,-20,'rotationz'}
	set{a+.25,20,'rotationz'}
	set{a+.5,-20,'rotationz'}
	set{a+.75,20,'rotationz'}
	local a = 451
	set{a,-20,'rotationz'}
	set{a+.25,20,'rotationz'}
	set{a+.5,-20,'rotationz'}
	set{a+.75,0,'rotationz'}
	set{458,100,'bumpyy'}{460,0,'bumpyy'}
	ease{465,0.5,inSine,100,'digital'}{468,0.5,inSine,0,'digital'}
	ease{452,0.1,linear,50,'zoom'}
	ease{455,0.1,linear,100,'zoom'}
	ease{468.5,0.1,linear,50,'skewx'}
	ease{468.75,0.3,linear,0,'skewx'}
	ease{469.25,0.1,linear,-50,'skewx'}
	ease{469.5,0.3,linear,0,'skewx'}
	local arrow_size = 112
	set{470,100 * arrow_size,'moveyoffset'}
	ease{470,1,outCubic,0,'moveyoffset'}
	set{471,-100 * arrow_size,'moveyoffset'}
	ease{471,1,outCubic,0,'moveyoffset'}

	ease{536,1,inCubic,100,'drunky',100,'wave',50,'drunk',300,'drunkspacing'}
	ease{539,3,linear,50,'zigzag'}
	ease{552,564,m='e',outCubic,0,'swap',0,'dark',0,'stealth',0,'zigzag',0,'digital'}
	set{560,200,'gayholds'}
	ease{564,1,linear,0,'gayholds'}
	set{565,200,'tipsyz',200,'square',200,'tipsy'}
	ease{565,1,outCubic,0,'tipsyz',0,'square',0,'tipsy'}
	set{566,-200,'tipsyz',-200,'square',-200,'tipsy'}
	ease{566,0.75,outCubic,0,'tipsyz',0,'square',0,'tipsy'}
	set{566.75,200,'tipsyz',200,'square',200,'tipsy'}
	ease{566.75,0.75,outCubic,0,'tipsyz',0,'square',0,'tipsy'}
	set{567.5,200,'tipsyz',200,'square',200,'tipsy'}
	ease{567.5,0.5,outCubic,0,'tipsyz',0,'square',0,'tipsy',0,'drunky',0,'wave',0,'drunk',0,'drunkspacing'}

	local state = 1
	rand = {}
	function rand.bool(p)
		return rand.float() < (p or 0.5)
	end
	function rand.float(a, b)
		state = state + 1
		local r = math.abs((math.sin(632459.86 * state) * 1023341.55) % 1)
		if not a then
			return r
		elseif not b then
			return r * a
		else
			return r * (a-b) + b
		end
	end
	function rand.int(a, b, c)
		if not b then
			a, b = 1, a
		end
		c = c or 1
		return math.floor(rand.float() * (b - a) / c) * c + a
	end
	function rand.seed(x)
		state = x
	end

	rand.seed(os.clock())
	local snareclap = {569,571,573,575,577,579,581,583,585,587,589,591,593,595,597,599,601,603,605,607,609,611,613,615,617,619,621,623,625,627,629,631}
	local clap = {598,598.75,599.5}
	set{568,500,'bumpyperiod'}
	local column = 0
	for _,v in pairs(snareclap) do
		set{v,200,'drunk',200,'tipsy',300,'bumpy',100,'arrowpath',rand.float(-30,30),'confusionoffset'..column,200,'scale'..column}
		ease{v,1,outCubic,0,'drunk',0,'tipsy',0,'bumpy',0,'arrowpath',0,'confusionoffset'..column,100,'scale'..column}
		column = column + 1
		if column >= 4 then column = 0 end
	end
	for _,v in pairs(clap) do
		set{v,-20,'flip'}
		ease{v,0.75,inSine,0,'flip'}
	end
	ease{568,1,inSine,200,'tipsyz',100,'tipsyx',50,'drunky',200,'drunkz',200,'bouncez'}
	ease{632,2,outElastic,0,'tipsyz',0,'tipsyx',0,'drunky',0,'drunkz',0,'bouncez',0,'drunkspeed',0,'tipsyspeed',50,'swap'}
	set{682,0,'drunkspeed',0,'tipsyspeed',0,'drunk',0,'tipsy'}
	local speed = 0
	local magnitude = 0
	definemod {"speed", "magnitude", function(s, m)
		speed = s / 100
		magnitude = m / 100
	end}
	ease {568, 1, inOutCirc, 100, "magnitude"}
	ease {568, 1, inOutSine, 0.5, "speed"}
	ease {600, 1, inOutSine, -0.5, "speed"}
	ease{630,1,inSine,0,'speed',0,'magnitude'}
	local lt, dt, t, wc = 0, 0, 0, 0
	local function mod(a, b) return a - math.floor(a/b)*b end
	func{564, 636-564, function(beat, poptions)
		t = getTime() * 60
		dt = t - lt
		lt = t
		for pn = 1,3 do
			for col = 0,3 do
				local o = (pn / 4) + (col / 16)
				local pos = mod(wc + o, 1)
				local cx = -2 + (4 * pos)
				poptions[pn]["movex"..col] = 600 * cx * magnitude
			end
		end
		wc = wc + (speed * dt)
	end}
	-- bandu part
	local e = ease
	e{648,3,linear,0.6,'xmod'}
	local a = {650,654,658,662,666,670,674,678}
	for i =1,#a do
		set{a[i],100,'dark',100,'stealth'}
		e{a[i],4,outSine,0,'dark',0,'stealth'}
	end
	e{680,2,outElastic,50,'swap',-300,'movey',100,'dark',100,'stealth'}
	local strength = 100
	definemod{'aaaaa',function(a)
		strength = a/100
	end}
	setdefault{100,'aaaaa'}
	func{696,744+8-696,function(b,p)
		for c=0,3 do
			p[2]['noteskewx'..c] = 50*math.sin(b/2+c*math.pi/2)*strength
			p[2]['noteskewy'..c] = 50*math.cos(b/2-c*math.pi/2)*strength
		end
	end}

	ease{744,8,linear,0,'aaaaa'}
	e{695,1,linear,0,'dark',0,'stealth',0,'movey',plr=2}
	ease{696-2,2,linear,-100,'brake',plr=2}ease{744,8,linear,0,'brake',plr=2}
	set{690,700,'movey1',700,'movey2',700,'movey3',700,'movey0',0,'movey',plr=1}
	e{695,7,inOutSine,0,'movey1',75,'dark',75,'stealth',plr=1}
	e{702,7,inOutSine,0,'movey2',75,'dark',75,'stealth',plr=1}
	e{710,7,inOutSine,0,'movey3',75,'dark',75,'stealth',plr=1}
	e{718,7,inOutSine,0,'movey0',75,'dark',75,'stealth',plr=1}
	e{728,4,outSine,200,'movey1',50,'movex1',0,'tipsyx',0,'tipsy',plr=1}
	e{736,4,outSine,200,'movey2',-50,'movex2',plr=1}
	e{742,6,outSine,200,'movey0',150,'movex0',200,'movey3',-150,'movex3',plr=1}
	for col = 0,3 do
		definemod {"rotationxcol"..col,
			function(_p1)
				local p = _p1
				if p % 360 == 0 then return 0, 0, 0, 0 end
				if p % 180 == 0 then return 100, 0, 0, 0 end
				local theta = p * math.pi / 180
				return 50 - 50 * math.cos(theta), 900, -212.5, 1000 * math.sin(theta)
			end,
		 "reverse"..col, "zigzagzperiod"..col, "zigzagzoffset"..col, "zigzagz"..col}
		 definemod {"rotationzcol"..col,
			function(_p1)
				local p = _p1
				if p % 360 == 0 then return 0, 0, 0, 0 end
				if p % 180 == 0 then return 100, 0, 0, 0 end
				local theta = p * math.pi / 180
				return 50 - 50 * math.cos(theta), 900, -212.5, 1000 * math.sin(theta)
			end,
		 "reverse"..col, "zigzagperiod"..col, "zigzagoffset"..col, "zigzag"..col}
	end

	e{696,2,linear,100,'tipsyx',100,'tipsy'}
	set{752,130,'scale'}
	e{752,2,outSine,100,"scale"}
	e{753,2,outSine,0,'dark',0,'stealth',0,'tipsy',0,'tipsyx'}
	e{759,4,inOutCirc,
	0,'movex0',0,'movey0',
	0,'movex1',0,'movey1',
	0,'movex2',0,'movey2',
	0,'movex3',0,'movey3'}
	e{760,1,linear,1,'xmod',100,'dizzy'}
	e{760,3,linear,300,'drunk',plr=2}
	e{760,3,linear,-300,'drunk',plr=1}
	set{775,200,'movex'}
	e{775,4,outSine,0,"movex"}
	set{775,200,'scale'}
	e{775,0.8,outSine,100,"scale"}
	set{791,130,'scale'}
	e{791,2,outSine,100,"scale"}
	e{776,15,linear,20,'drunkspeed'}
	e{791,1,outBounce,0,'drunk',0,'blink',20,'swap'}

	for i=792,798 do
		for j=0,3 do
			set{i,10,'rotationxcol'..j,-30,'rotationzcol'..j,300,'movez',50,'drunk',10,'tornado'}
			ease{i,0.5,outCubic,0,'rotationxcol'..j,0,'rotationzcol'..j,0,'movez',0,'drunk',0,'tornado'}
			set{i+0.5,-10,'rotationxcol'..j,30,'rotationzcol'..j,-300,'movez',-50,'drunk',-10,'tornado'}
			ease{i+0.5,0.5,outCubic,0,'rotationxcol'..j,0,'rotationzcol'..j,0,'movez',0,'drunk',0,'tornado'}
		end
	end
	ease{799,0.25,linear,torad(360),'confusionyoffset1'}ease{799.25,0.25,linear,torad(360),'confusionyoffset0'}ease{799.5,0.25,linear,torad(360),'confusionyoffset2'}ease{799.75,0.25,linear,torad(360),'confusionyoffset3'}
	set{800,0,'confusionyoffset1',0,'confusionyoffset2',0,'confusionyoffset3',0,'confusionyoffset0',plr=2}

	e{800,0.2,linear,400,'tandrunky',200,'beatz',100,'beatzmult'}
	e{804,0.2,outBounce,0,'tandrunky',100,'tandrunk'}
	e{807,0.1,outBounce,0,'tandrunk',100,'cross',0,'beatz',0,'beatzmult'}
	ease{807,1,linear,torad(360),'confusionoffset'}
	e{807.5,0.1,outBounce,0,'cross',100,'reverse0',100,'reverse3'}
	e{808,0.1,outBounce,0,'reverse0',0,'reverse3',25,'spiralx',25,'spiraly',-96,'spiralxperiod',-96,'spiralyperiod',200,'bumpy',500,'bumpyperiod',0,'swap'}
	e{816,3,outBounce,0,'spiralx',0,'spiraly',0,'spiralxperiod',0,'spiralyperiod',0,'bumpy',0,'bumpyperiod'}
	ease{808,8,inQuad,1000,'centered2',-1000,'movey'}
	ease{808,8,outInCubic,1000,'bumpyoffset'}
	set{820,200,'scale',0,'bumpyoffset',0,'centered2',0,'movey'}
	e{820,9,outSine,100,"scale",0,'dizzy'}

	-- end it

	local synth = {824,824.25,824.5,824.75,825,825.5,826,826.25,826.5,826.75,827,827.5,828,828,828.5,829,829.5,830,830.25,830.5,830.75,831,831.5,832,832.5,832.75,833,833.5,834,834.25,834.5,834.75,835,835.5}
	for _,i in pairs(synth) do
		set{i,rand.float(-20,20),'confusionoffset',rand.float(-10,10),'rotationy',rand.float(-10,10),'rotationz'}
	end
	set{836,0,'confusionoffset',0,'rotationy',0,'rotationz'}

	set{836,-100,'movex',-100,'movey0',100,'movey1',-100,'movey2',100,'movey3'}
	ease{836,0.5,outCubic,0,'movex',0,'movey0',0,'movey1',0,'movey2',0,'movey3'}
	set{836.5,100,'movex',100,'movey0',-100,'movey1',100,'movey2',-100,'movey3'}
	ease{836.5,0.5,outCubic,0,'movex',0,'movey0',0,'movey1',0,'movey2',0,'movey3'}
	set{837,-100,'movex',-100,'movey0',100,'movey1',-100,'movey2',100,'movey3'}
	ease{837,0.5,outCubic,0,'movex',0,'movey0',0,'movey1',0,'movey2',0,'movey3'}
	set{837.5,100,'movex',100,'movey0',-100,'movey1',100,'movey2',-100,'movey3'}
	ease{837.5,0.5,outCubic,0,'movex',0,'movey0',0,'movey1',0,'movey2',0,'movey3'}
	set{838,-100,'movex',-100,'movey0',100,'movey1',-100,'movey2',100,'movey3',100,'drunk',100,'tipsy'}
	ease{838,0.5,outCubic,0,'movex',0,'movey0',0,'movey1',0,'movey2',0,'movey3',0,'drunk',0,'tipsy'}
	ease{839,0.9,linear,torad(360),'confusionxoffset',torad(360),'confusionyoffset',torad(360),'confusionoffset'}
	ease{839,1,inOutElastic,50,'swap'}
	ease{840,0.1,linear,0,'confusionxoffset',0,'confusionyoffset',0,'confusionoffset'}



	-- halo
	local halo = 0
	local halospeed = 1
	definemod{'halo','halospeed', function(a,b)
		halo = a / 100
		halospeed = b / 100
	end}
	setdefault{0,'halo',100,'halospeed'}
	set{840,100,'halo',100,'halospeed',300,'movey',100,'stealth',plr=1}
	func{840,884-840,function(beat, p)
		for col=0,3 do
			local ang2 = halospeed * beat + math.pi / 6 * col
			local size = 200
			p[1]['movex'..col] = size * halo * math.cos(ang2) - 100 * col + 100
			p[1]['movez'..col] = 50 * halo * math.sin(ang2)
			p[1]['movey'..col] = size * math.sin(-beat / 2) * halo
			p[1]['confusionyoffset'..col] = 100 * math.atan2(size * halo * math.cos(ang2), size * halo * math.sin(ang2))
			p[1].z = size * math.sin(beat / 2) * math.cos(-beat / 2)
		end
		p[2].movex = math.cos(beat / 2) * 200
		p[2].movey = math.sin(beat / 2) * 100 + 50
		p[2].movez = math.sin(beat / 2) * 150
		p[2].rotationz = math.sin(beat / 2.5) * 20
		p[2].rotationy = math.cos(beat / 2.5) * 3
	end}

	-- too much speedcore kicks
	local kickspart1 = {840,840.5,841,841.5,842,842.5,843,843.5,843.75,844,844.5,845,845.5,846,846.35,846.5,846.75,847.5,847.625,847.75,847.875,848,849,849.5,850,850.5,851,851.5,851.75,852,852.5,853,853.5,854,854.25,854.5,854.75,855,855.25,855.5,855.625,855.75,855.875,856,856.5,856.75,857,857.5,857.75,858,858.5,858.75,859,859.5,859.75,860,860.5,860.75,861,861.5,861.75,862,862.5,862.75,864,864.5,864.75,865,865.5,865.75,866,866.5,866.75,867,867.5,867.75,868,868.5,868.75,869,869.5,869.75,870,870.5,870.75,872,872.5,873,873.5,874,874.5,875,875.5,875.625,875.75,875.875,876,876.5,877,877.5,878,878.5,878.625,878.75,878.875,879,879.25,879.5,879.75,880,880.5,881,881.5,882,882.5,883,883.125,883.25,883.375,883.5,883.625,883.75,883.875,884,885,886,887,887.5}
	local a=1
	for k,v in pairs(kickspart1) do
		set{v,80*a,'drunk',80*a,'tipsy',-10,'flip',200,'beat',plr=2}
		local aaa = kickspart1[k+1]
		if aaa == nil then aaa = v+1 end
		ease{v,aaa-v,outSine,0,'drunk',0,'tipsy',0,'flip',0,'beat'}
		a=a*-1
	end
	for col=0,3 do
	ease{884,1,inOutCirc,0,'movex',0,'movex'..col,0,'movey',0,'movey'..col,0,'movez',0,'movez'..col,0,'rotationz',0,'rotationy',0,'confusionyoffset'..col}
	end
	ease{888,1,inSine,50,'skewx',-20,'rotationz'}
	ease{888,1,linear,100,'dark',plr=1}
	ease{889,1,inSine,-50,'skewx',20,'rotationz'}
	ease{890,0.5,inSine,30,'skewx',-10,'rotationz'}
	ease{890.5,0.5,inSine,-40,'skewx',20,'rotationz'}
	ease{891,1,inSine,50,'skewx',-30,'rotationz'}
	set{891,-20,'flip',150,'scaley'}
	ease{891,1,outInCirc,0,'flip',100,'scaley'}
	ease{892,0.5,inSine,50,'skewx',-20,'rotationz'}
	ease{892.5,0.5,inSine,-30,'skewx',40,'rotationz'}
	ease{893,1,inSine,20,'skewx',-40,'rotationz'}
	ease{894,1,inSine,-10,'skewx',40,'rotationz'}
	ease{890,0.5,inSine,30,'skewx',-40,'rotationz'}
	ease{895,1,inSine,0,'skewx',0,'rotationz'}
	set{895,200,'bounce',300,'square',200,'digital',400,'zigzag'}
	ease{895,1,inCirc,0,'bounce',0,'square',0,'digital',0,'zigzag'}
	ease{896,1,inOutSine,200,'drunk'}
	set{897,200,'scale2',200,'scale3'}
	ease{897,1,outCubic,100,'scale2',100,'scale3'}
	set{899,200,'scale2',200,'scale3'}
	ease{899,1,outCubic,100,'scale2',100,'scale3'}
	set{901,200,'scale2',200,'scale3'}
	ease{901,1,outCubic,100,'scale2',100,'scale3'}
	set{902,100,'movex'}
	set{902.25,-100,'movex'}
	set{902.5,100,'movex'}
	set{902.75,-100,'movex'}
	set{903,100,'movex'}
	set{903.5,100,'movex1',100,'movex3',-100,'movex2',-100,'movex0'}
	ease{903,1,outElastic,0,'dark',0,'stealth',plr=1}
	ease{903.5,0.5,inSine,0,'movex1',0,'movex2',0,'movex3',0,'movex0',0,'tipsy'}
	ease{903.5,0.5,inSine,0,'drunk',plr=1}
	local kickspart2 = {904,904.5,905,905.5,906,906.5,907,907.5,908,908.5,909,909.5,910,910.5,910.75,911.5,911,912,912.5,913,913.5,914,914.5,915,915.5,916,916.5,917,917.5,918,918.5,919,919.5}
	local a=1
	for k,v in pairs(kickspart2) do
		set{v,80*a,'drunk',80*a,'tipsy',-10,'flip',200,'beat',plr=2}
		local aaa = kickspart2[k+1]
		if aaa == nil then aaa = v+1 end
		ease{v,aaa-v,outSine,0,'drunk',0,'tipsy',0,'flip',0,'beat'}
		a=a*-1
	end
	ease{903,1,inCubic,100,'centered',-500,'movez',plr=1}
	func{904,920-904,function(beat,p)
		p[2].movex = math.cos(beat / 2) * 300
		p[2].movey = math.sin(beat / 2) * 100 + 50
		p[2].movez = math.sin(beat / 2) * 400
		p[2].rotationz = math.sin(beat / 2.5) * 10
		p[2].rotationy = math.cos(beat / 2.5) * 5
		p[2].drunk = math.sin(beat / 2) * 50
		p[1].digital = math.sin(beat / 4) * 360
		p[1].zigzag = math.abs(math.cos(beat * math.pi / 4))
		p[1].stealth = 85 + 10 * math.sin(beat / 4)
		p[1].rotationx = math.sin(beat / 10) * 360
	end}
	ease{920,1,inSine,0,'movex',0,'movey',0,'movez',0,'rotationx',0,'rotationy',0,'rotationz',0,'zigzag',0,'digital',0,'stealth',0,'drunk',0.8,'xmod'}

	for col=0,3 do
		ease{920,1,inSine,0,'drunk'..col,0,'drunkz'..col}
	end
	for pn=1,2 do
	ease{920,1,inSine,200*(-2 * pn + 3),'tornado',200*(-2 * pn + 3),'tornadoz',1000*(-2 * pn + 3),'bumpyx',1000*(-2 * pn + 3),'bumpy',-100,'spiralholds',400,'bumpyxperiod',200,'bumpyperiod',200,'tiny',plr=pn}
	end
	set{920,100,'drunk',100,'tipsy'}
	ease{920,1,inSine,100,'dark',100,'stealth',plr=1}
	set{927,100,'dark',100,'stealth',plr=2}
	set{928,0,'dark',0,'stealth',plr=2}
	set{928,40,'shrinklinear',400,'zigzag',400,'zigzagz',300,'zigzagzperiod',200,'bouncez',100,'reverse'}
	set{935,100,'dark',100,'stealth',plr=2}
	set{936,0,'dark',0,'stealth',plr=2}
	set{936,50,'reverse',0,'bouncez',0,'zigzag',0,'shrinklinear',0,'zigzagz',0,'zigzagzperiod',0,'tornado',0,'tornadoz',0,'bumpyx',0,'bumpy',0,'bumpyxperiod',0,'bumpyperiod',50,'swap',50,'flip',0,'drunk',0,'tiny',0,'tipsy'}
	set{936,100,'spiralx',100,'spiraly',plr=1}
	set{936,-100,'spiralx',-100,'spiraly',plr=2}
	set{936,-95,'spiralxperiod',-95,'spiralyperiod',200,'confusion'}

	ease{948,4,inQuad,0,'spiralx',0,'spiraly',0,'spiralxperiod',0,'spiralyperiod',0,'confusion',0,'reverse',0,'tiny',0,'flip'}
	ease{948,1,inSine,torad(-45),'confusionoffset0',torad(-22.5),'confusionoffset1',torad(22.5),'confusionoffset0',torad(45),'confusionoffset1',100,'tipsy'}
	ease{949,2,inQuad,800,'movey'}

	set{952,-200,'movey',0,'swap',0,'stealth',0,'dark',0,'centered'}
	for col=0,3 do
		set{952,0,'confusionoffset'..col}
	end
	ease{952,1,outQuad,100,'movey',0,'tipsy',100,'tipsyx',100,'drunky',100,'brake'}
	ease{1016,1,outQuad,40,'orientx',40,'orienty'}
	ease{1072.5,1,inOutSine,-200,'movey0',-45,'confusionoffset0',100,'dark0',100,'stealth0'}
	ease{1074,1,inOutSine,-200,'movey1',-22.5,'confusionoffset1',100,'dark1',100,'stealth1'}
	ease{1076.5,1,inOutSine,-200,'movey3',45,'confusionoffset3',100,'dark3',100,'stealth3'}
	ease{1078,1,inOutSine,-200,'movey2',22.5,'confusionoffset2',100,'dark2',100,'stealth2'}
	end
end
function onReady()
	initMods()
  sort_tables()
	resolve_aliases()
	compile_nodes()
	for i = 1, max_pn do
		mod_buffer[i]:clear()
	end
	run_nodes()
	run_mods()
end
function onUpdate()
	setHealth(2)
	local beat = getBeat()
	local time = getTime()
  run_eases(beat, time)
	run_funcs(beat, time)
	run_nodes()
  run_mods()
end
