-- Round-trip tests for storage/bitcodec.lua (BitEncoder/BitDecoder).

dofile("BattleScrolls/storage/bitcodec.lua")
local BitEncoder = BattleScrolls.bitcodec.BitEncoder
local BitDecoder = BattleScrolls.bitcodec.BitDecoder

describe("BitCodec", function()
    it("round-trips fixed-width uints at boundary values", function()
        local cases = {
            { 0, 1 }, { 1, 1 },
            { 0, 4 }, { 15, 4 },
            { 0, 8 }, { 255, 8 },
            { 4095, 12 }, { 65535, 16 },
            { 2 ^ 24 - 1, 24 },
            { 2 ^ 30 - 1, 30 }, -- damage totals width
            { 12345678, 30 },
        }
        local encoder = BitEncoder.new()
        for _, c in ipairs(cases) do
            encoder:writeUInt(c[1], c[2])
        end
        local decoder = BitDecoder.new(encoder:finish())
        for i, c in ipairs(cases) do
            assert_eq(decoder:readUInt(c[2]), c[1], "case " .. i)
        end
    end)

    it("round-trips bits and non-byte-aligned mixes", function()
        local encoder = BitEncoder.new()
        encoder:writeBit(true)
        encoder:writeUInt(300, 12)
        encoder:writeBit(false)
        encoder:writeUInt(77, 7)
        encoder:writeBit(true)
        local decoder = BitDecoder.new(encoder:finish())
        assert_eq(decoder:readBit(), true, "bit 1")
        assert_eq(decoder:readUInt(12), 300, "12-bit value")
        assert_eq(decoder:readBit(), false, "bit 2")
        assert_eq(decoder:readUInt(7), 77, "7-bit value")
        assert_eq(decoder:readBit(), true, "bit 3")
    end)

    it("round-trips varuints across group boundaries", function()
        local values = { 0, 1, 127, 128, 255, 300, 16383, 16384,
            2 ^ 21, 2 ^ 30 + 12345, 2 ^ 40 + 7 }
        local encoder = BitEncoder.new()
        for _, v in ipairs(values) do
            encoder:writeVarUInt(v)
        end
        local decoder = BitDecoder.new(encoder:finish())
        for i, v in ipairs(values) do
            assert_eq(decoder:readVarUInt(), v, "value " .. i)
        end
    end)

    it("round-trips strings including empty and 255-byte max", function()
        local long = string.rep("x", 255)
        local strings = { "", "a", "hello world", "@Player-Name", long }
        local encoder = BitEncoder.new()
        for _, s in ipairs(strings) do
            encoder:writeString(s)
        end
        local decoder = BitDecoder.new(encoder:finish())
        for i, s in ipairs(strings) do
            assert_eq(decoder:readString(), s, "string " .. i)
        end
    end)

    it("truncates strings longer than 255 bytes", function()
        local encoder = BitEncoder.new()
        encoder:writeString(string.rep("y", 300))
        local decoder = BitDecoder.new(encoder:finish())
        assert_eq(decoder:readString(), string.rep("y", 255), "truncated string")
    end)

    it("alignToByte pads symmetrically", function()
        local encoder = BitEncoder.new()
        encoder:writeUInt(5, 3)
        encoder:alignToByte()
        encoder:writeString("aligned")
        encoder:writeBit(true)
        encoder:alignToByte()
        encoder:writeVarUInt(999)
        local decoder = BitDecoder.new(encoder:finish())
        assert_eq(decoder:readUInt(3), 5, "pre-align value")
        decoder:alignToByte()
        assert_eq(decoder:readString(), "aligned", "aligned string")
        assert_eq(decoder:readBit(), true, "bit after string")
        decoder:alignToByte()
        assert_eq(decoder:readVarUInt(), 999, "aligned varuint")
    end)

    it("spans multiple chunks and decodes across boundaries", function()
        -- 180-byte flush threshold: write well past several flushes
        local encoder = BitEncoder.new()
        for i = 1, 1000 do
            encoder:writeVarUInt(i * 7919) -- primes avoid accidental patterns
        end
        local chunks = encoder:finish()
        assert_true(#chunks > 1, "should produce multiple chunks, got " .. #chunks)
        local decoder = BitDecoder.new(chunks)
        for i = 1, 1000 do
            assert_eq(decoder:readVarUInt(), i * 7919, "value " .. i)
        end
    end)

    it("survives a deterministic interleaved torture sequence", function()
        -- Simple LCG so the sequence is identical on every Lua version
        local seed = 42
        local function nextRand(max)
            seed = (seed * 1103515245 + 12345) % 2147483648
            return seed % max
        end
        local ops = {}
        local encoder = BitEncoder.new()
        for _ = 1, 2000 do
            local kind = nextRand(4)
            if kind == 0 then
                local bits = 1 + nextRand(30)
                local value = nextRand(2 ^ bits)
                encoder:writeUInt(value, bits)
                ops[#ops + 1] = { "uint", value, bits }
            elseif kind == 1 then
                local value = nextRand(2 ^ 31)
                encoder:writeVarUInt(value)
                ops[#ops + 1] = { "var", value }
            elseif kind == 2 then
                local bit = nextRand(2)
                encoder:writeBit(bit == 1)
                ops[#ops + 1] = { "bit", bit }
            else
                encoder:alignToByte()
                local len = nextRand(20)
                local chars = {}
                for i = 1, len do
                    chars[i] = string.char(32 + nextRand(90))
                end
                local str = table.concat(chars)
                encoder:writeString(str)
                ops[#ops + 1] = { "str", str }
            end
        end
        local decoder = BitDecoder.new(encoder:finish())
        for i, op in ipairs(ops) do
            if op[1] == "uint" then
                assert_eq(decoder:readUInt(op[3]), op[2], "op " .. i .. " uint")
            elseif op[1] == "var" then
                assert_eq(decoder:readVarUInt(), op[2], "op " .. i .. " varuint")
            elseif op[1] == "bit" then
                assert_eq(decoder:readBit(), op[2] == 1, "op " .. i .. " bit")
            else
                decoder:alignToByte()
                assert_eq(decoder:readString(), op[2], "op " .. i .. " string")
            end
        end
    end)
end)
