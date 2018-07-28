--[[
UTF-8的编码规则
  |  Unicode符号范围      |  UTF-8编码方式
n |  (十六进制)           | (二进制)
---+-----------------------+------------------------------------------------------
1 | 0000 0000 - 0000 007F |                                              0xxxxxxx
2 | 0000 0080 - 0000 07FF |                                     110xxxxx 10xxxxxx
3 | 0000 0800 - 0000 FFFF |                            1110xxxx 10xxxxxx 10xxxxxx
4 | 0001 0000 - 0010 FFFF |                   11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
5 | 0020 0000 - 03FF FFFF |          111110xx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
6 | 0400 0000 - 7FFF FFFF | 1111110x 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
--]]

local bit_blshift = bit.lshift or bit.blshift
local bit_band = bit.band
local bit_brshift = bit.rshift or bit.brshift

local M = {}

function M.enc_get_utf8_bytes(char)
    if char >= 0 and char < 0x80 then
        return 1
    elseif char >= 0xc0 and char < 0xe0  then
        return 2
    elseif char >= 0xe0 and char < 0xf0 then
        return 3
    elseif char >= 0xf0 and char < 0xf8 then
        return 4
    elseif char >= 0xf8 and char < 0xfc then
        return 5
    elseif char >= 0xfc and char < 0xfe then
        return 6
    else
        return -1
    end
end

function M.split_utf8_character_list(str)
    local len = string.len(str)
    local list = {}
    local i = 1
    while i <= len do
        local c = string.byte(str, i)
        local utfbytes = M.enc_get_utf8_bytes(c)
        if utfbytes == -1 then
            break
        end

        local character = string.sub(str, i, i+utfbytes-1)
        table.insert(list, character)
        i = i + utfbytes
    end

    return list
end

function M.enc_utf8_to_unicode(str)
    local len = string.len(str)
    local list = {}
    local i = 1
    while i <= len do
        local c = string.byte(str, i)
        local utfbytes = M.enc_get_utf8_bytes(c)
        if utfbytes == -1 then
            break
        end

        local character = string.sub(str, i, i+utfbytes-1)
        --character = string.format("\\u%x", M.enc_utf8_to_unicode_one(character))
        character = M.enc_utf8_to_unicode_one(character)
        table.insert(list, character)
        i = i + utfbytes
    end

    return list
end

--大端（高位优先）
function M.enc_utf8_to_unicode_one(character)
    local c = string.byte(character, 1)
    local utfbytes = M.enc_get_utf8_bytes(c)
    if utfbytes == -1 then
        return
    end

    local unicode
    local b1, b2, b3, b4, b5, b6
    local c1, c2, c3, c4, c5, c6
    if utfbytes == 1 then
        unicode = c
    elseif utfbytes == 2 then
        b1 = string.byte(character, 1)
        b2 = string.byte(character, 2)
        if bit_band(b2, 0xc0) ~= 0x80 then
            return
        end

        c1 = bit_band(bit_band(bit_brshift(b1, 2), 0xff), 0x07)
        c2 = bit_band(bit_blshift(b1, 6), 0xff) + bit_band(b2, 0x3f)

        unicode = bit_blshift(c1, 8) + c2
    elseif utfbytes == 3 then
        b1 = string.byte(character, 1)
        b2 = string.byte(character, 2)
        b3 = string.byte(character, 3)

        if bit_band(b2, 0xc0) ~= 0x80 or bit_band(b3, 0xc0) ~= 0x80 then
            return
        end

        c1 = bit_band(bit_blshift(b1, 4), 0xff) + bit_band(bit_band(bit_brshift(b2, 2), 0xff), 0x0f)
        c2 = bit_band(bit_blshift(b2, 6), 0xff) + bit_band(b3, 0x3f)

        unicode = bit_blshift(c1, 8) + c2
    elseif utfbytes == 4 then
        b1 = string.byte(character, 1)
        b2 = string.byte(character, 2)
        b3 = string.byte(character, 3)
        b4 = string.byte(character, 4)

        if bit_band(b2, 0xc0) ~= 0x80 or bit_band(b3, 0xc0) ~= 0x80 or bit_band(b4, 0xc0) ~= 0x80 then
            return
        end

        c1 = bit_band(bit_band(bit_blshift(b1, 2), 0xff), 0x1c) + bit_band(bit_band(bit_brshift(b2, 4), 0xff), 0x03)
        c2 = bit_band(bit_blshift(b2, 4), 0xff) + bit_band(bit_band(bit_brshift(b3, 2), 0xff), 0x0f)
        c3 = bit_band(bit_blshift(b3, 6), 0xff) + bit_band(b4, 0x3f)

        unicode = bit_blshift(c1, 16) + bit_blshift(c2, 8) + c3
    elseif utfbytes == 5 then
        b1 = string.byte(character, 1)
        b2 = string.byte(character, 2)
        b3 = string.byte(character, 3)
        b4 = string.byte(character, 4)
        b5 = string.byte(character, 5)

        if bit_band(b2, 0xc0) ~= 0x80 or bit_band(b3, 0xc0) ~= 0x80 or bit_band(b4, 0xc0) ~= 0x80 or bit_band(b5, 0xc0) ~= 0x80 then
            return
        end

        c1 = bit_band(b1, 0x03)
        c2 = bit_band(bit_blshift(b2, 2), 0xff) + bit_band(bit_brshift(b3, 4), 0x03)
        c3 = bit_band(bit_blshift(b3, 4), 0xff) + bit_band(bit_brshift(b4, 2), 0x0f)
        c4 = bit_band(bit_blshift(b4, 6), 0xff) + bit_band(b5, 0x3f)

        unicode = bit_blshift(c1, 24) + bit_blshift(c2, 16) + bit_blshift(c3, 8) + c4
    elseif utfbytes == 6 then
        b1 = string.byte(character, 1)
        b2 = string.byte(character, 2)
        b3 = string.byte(character, 3)
        b4 = string.byte(character, 4)
        b5 = string.byte(character, 5)
        b6 = string.byte(character, 6)

        if bit_band(b2, 0xc0) ~= 0x80 or bit_band(b3, 0xc0) ~= 0x80 or bit_band(b4, 0xc0) ~= 0x80 or bit_band(b5, 0xc0) ~= 0x80
                or bit_band(b6, 0xc0) ~= 0x80 then
            return
        end

        c1 = bit_band(bit_blshift(b1, 6), 0x40) + bit_band(b2, 0x3f)
        c2 = bit_band(bit_blshift(b3, 2), 0xff) + bit_band(bit_brshift(b4, 4), 0x03)
        c3 = bit_band(bit_blshift(b4, 4), 0xff) + bit_band(bit_brshift(b5, 2), 0x0f)
        c4 = bit_band(bit_blshift(b5, 6), 0xff) + bit_band(b6, 0x3f)

        unicode = bit_blshift(c1, 24) + bit_blshift(c2, 16) + bit_blshift(c3, 8) + c4
    end

    return unicode
end

return M