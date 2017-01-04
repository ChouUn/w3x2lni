local select = select
local string_lower = string.lower
local string_unpack = string.unpack
local string_match = string.match

local w2l
local wts
local has_level
local unpack_buf
local unpack_pos
local force_slk

local function set_pos(...)
    unpack_pos = select(-1, ...)
    return ...
end

local function unpack(str)
    return set_pos(string_unpack(str, unpack_buf, unpack_pos))
end

local function read_data(obj)
    local data = {}
    local id = string_match(unpack 'c4', '^[^\0]+')
    local value_type = unpack 'l'
    local level = 0

    --是否包含等级信息
    if has_level then
        local this_level = unpack 'l'
        level = this_level
        -- 扔掉一个整数
        unpack 'l'
    end

    local value
    if value_type == 0 then
        value = unpack 'l'
    elseif value_type == 1 or value_type == 2 then
        value = unpack 'f'
    else
        local str = unpack 'z'
        value = wts:load(str)
    end
    
    -- 扔掉一个整数
    unpack 'l'
    
    if level == 0 then
        level = 1
    end
    if not obj[id] then
        obj[id] = {}
    end
    obj[id][level] = value
end

local function read_obj(chunk, type)
    local parent, name = unpack 'c4c4'
    if name == '\0\0\0\0' then
        name = parent
    end
    if not w2l:is_usable_para(parent) then
        force_slk = true
    end
    local obj = {
        _id = name,
        _parent = parent,
        _type = type,
        _obj = true,
    }

    local count = unpack 'l'
    for i = 1, count do
        read_data(obj)
    end
    chunk[name] = obj
    return obj
end

local function read_version()
    return unpack 'l'
end

local function read_chunk(chunk, type)
    local count = unpack 'l'
    for i = 1, count do
        local obj = read_obj(chunk, type)
    end
end

return function (w2l_, type, wts_, buf)
    w2l = w2l_
    wts = wts_
    has_level = w2l.info.key.max_level[type]
    unpack_buf = buf
    unpack_pos = 1
    force_slk = false
    local data    = {}
    -- 版本号
    read_version()
    -- 默认数据
    read_chunk(data, type)
    -- 自定义数据
    read_chunk(data, type)
    return data, force_slk
end
