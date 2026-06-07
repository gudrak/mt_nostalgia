-- Mapgen aliases
minetest.register_alias("mapgen_air", "air")
minetest.register_alias("mapgen_stone", "default:stone")
minetest.register_alias("mapgen_tree", "default:tree")
minetest.register_alias("mapgen_leaves", "default:leaves")
minetest.register_alias("mapgen_jungletree", "default:tree")
minetest.register_alias("mapgen_jungleleaves", "default:leaves")
minetest.register_alias("mapgen_apple", "default:apple")
minetest.register_alias("mapgen_water_source", "default:water_source")
minetest.register_alias("mapgen_river_water_source", "default:water_source")
minetest.register_alias("mapgen_dirt", "default:mud")
minetest.register_alias("mapgen_sand", "default:sand")
minetest.register_alias("mapgen_gravel", "default:stone")
minetest.register_alias("mapgen_clay", "default:sand")
minetest.register_alias("mapgen_lava_source", "default:lava_source")
minetest.register_alias("mapgen_cobble", "default:stone")
minetest.register_alias("mapgen_mossycobble", "default:stone")
minetest.register_alias("mapgen_dirt_with_grass", "default:grass")
minetest.register_alias("mapgen_junglegrass", "default:grass")
minetest.register_alias("mapgen_stone_with_coal", "default:stone_with_coal")
minetest.register_alias("mapgen_stone_with_iron", "default:stone")
minetest.register_alias("mapgen_mese", "default:mese")
minetest.register_alias("mapgen_desert_sand", "default:dirt")
minetest.register_alias("mapgen_desert_stone", "default:stone")
minetest.register_alias("mapgen_ice", "default:stone") 
minetest.register_alias("mapgen_snow", "air")
minetest.register_alias("mapgen_snowblock", "default:stone")

-- Ore generation
function default.register_ores()
    local ore_definitions = {
        { ore = "default:stone_with_coal", scarcity = 8*8*8,    num = 8,  size = 3, min = -31000, max = 64 },
        { ore = "default:stone_with_coal", scarcity = 24*24*24, num = 27, size = 6, min = -31000, max = 0,    flags = "absheight" },
        { ore = "default:stone_with_iron", scarcity = 12*12*12, num = 3,  size = 2, min = -15,    max = 2 },
        { ore = "default:stone_with_iron", scarcity = 9*9*9,    num = 5,  size = 3, min = -63,    max = -16 },
        { ore = "default:stone_with_iron", scarcity = 7*7*7,    num = 5,  size = 3, min = -31000, max = -64,   flags = "absheight" },
        { ore = "default:stone_with_iron", scarcity = 24*24*24, num = 27, size = 6, min = -31000, max = -64,   flags = "absheight" },
        { ore = "default:mese",            scarcity = 18*18*18, num = 3,  size = 2, min = -255,   max = -64,   flags = "absheight" },
        { ore = "default:mese",            scarcity = 14*14*14, num = 5,  size = 3, min = -31000, max = -256,  flags = "absheight" },
        { ore = "default:mese",            scarcity = 36*36*36, num = 3,  size = 2, min = -31000, max = -1024, flags = "absheight" }
    }

    for _, def in ipairs(ore_definitions) do
        minetest.register_ore({
            ore_type       = "scatter",
            ore            = def.ore,
            wherein        = "default:stone",
            clust_scarcity = def.scarcity,
            clust_num_ores = def.num,
            clust_size     = def.size,
            height_min     = def.min,
            height_max     = def.max,
            flags          = def.flags
        })
    end
end

-- Biome registration
function default.register_biomes()
    minetest.clear_registered_biomes()

    local biome_definitions = {
        { name = "stone_grassland",        top = "default:grass", d_top = 1, filler = "default:dirt", d_filler = 0, min = 5,    max = 31000, heat = 45, humid = 25 },
        { name = "stone_land_ocean",       top = "default:sand",  d_top = 1, filler = "default:sand", d_filler = 2, min = -112, max = 4,     heat = 45, humid = 25 },
        { name = "deciduous_forest",       top = "default:grass", d_top = 1, filler = "default:dirt", d_filler = 2, min = 1,    max = 31000, heat = 70, humid = 75 },
        { name = "deciduous_forest_swamp", top = "default:dirt",  d_top = 1, filler = "default:dirt", d_filler = 2, min = -3,   max = 0,     heat = 70, humid = 75 },
        { name = "deciduous_forest_ocean", top = "default:sand",  d_top = 1, filler = "default:sand", d_filler = 2, min = -112, max = -4,    heat = 70, humid = 75 },
        { name = "desert",                 top = "default:sand",  d_top = 1, filler = "default:sand", d_filler = 1, min = 5,    max = 31000, heat = 95, humid = 10, stone = "default:stone" },
        { name = "desert_ocean",           top = "default:sand",  d_top = 1, filler = "default:sand", d_filler = 2, min = -112, max = 4,     heat = 95, humid = 10, stone = "default:stone" },
        { name = "underground",            top = nil,             d_top = 0, filler = nil,            d_filler = 0, min = -31000, max = -113,  heat = 50, humid = 50 }
    }

    for _, def in ipairs(biome_definitions) do
        minetest.register_biome({
            name            = def.name,
            node_top        = def.top,
            depth_top       = def.d_top,
            node_filler     = def.filler,
            depth_filler    = def.d_filler,
            node_stone      = def.stone,
            y_min           = def.min,
            y_max           = def.max,
            heat_point      = def.heat,
            humidity_point  = def.humid
        })
    end
end

-- Decorations registration
function default.register_decorations()
    minetest.clear_registered_decorations()

    minetest.register_decoration({
        deco_type = "schematic",
        place_on = {"default:grass"},
        sidelen = 16,
        noise_params = {
            offset = 0.04,
            scale = 0.02,
            spread = {x = 250, y = 250, z = 250},
            seed = 2,
            octaves = 3,
            persist = 0.66
        },
        biomes = {"deciduous_forest"},
        y_min = 1,
        y_max = 31000,
        schematic = minetest.get_modpath("default") .. "/schematics/apple_tree.mts",
        flags = "place_center_x, place_center_z",
    })
end

-- Initialization based on Mapgen version
local mg_params = minetest.get_mapgen_params()

if mg_params.mgname == "v6" then
    default.register_ores()
elseif mg_params.mgname ~= "singlenode" then
    default.register_ores()
    default.register_biomes()
    default.register_decorations()
end
