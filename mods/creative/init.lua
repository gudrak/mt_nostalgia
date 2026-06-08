creative_inventory = {}
creative_inventory.creative_inventory_size = 0

function creative_inventory.is_creative(player)
    if not player then return false end
    local name = player:get_player_name()
    return minetest.check_player_privs(name, {creative = true}) or
           minetest.settings:get_bool("creative_mode")
end

local function is_inv_empty(inv)
    local lists = inv:get_lists()
    for k, v in pairs(lists) do
        if not inv:is_empty(k) then return false end
    end
    return true
end

-- 1. LÓGICA DE PICADO (BLOQUEO DE DROPS Y VACIADO DE INVENTARIOS)
minetest.register_on_mods_loaded(function()
    for name, def in pairs(minetest.registered_nodes) do
        -- Guardamos las funciones originales de cada nodo
        local original_on_dig = def.on_dig
        local original_can_dig = def.can_dig

        -- 1.1. Permitir a los jugadores creativos picar cofres llenos
        if original_can_dig then
            minetest.override_item(name, {
                can_dig = function(pos, player)
                    if player and creative_inventory.is_creative(player) then
                        return true
                    end
                    return original_can_dig(pos, player)
                end
            })
        end

        -- 1.2. Sobrescribir el evento de picado de forma segura
        if original_on_dig then
            minetest.override_item(name, {
                on_dig = function(pos, node, digger, ...)
                    if not digger or not creative_inventory.is_creative(digger) then
                        -- MODO SUPERVIVENCIA: Usamos la función original del nodo sin riesgo de nil
                        return original_on_dig(pos, node, digger, ...)
                    end

                    -- ==== MODO CREATIVO ====
                    local inv_player = digger:get_inventory()
                    local node_name = node.name

                    -- Rescatar inventario de cofres ANTES de que el motor destruya el nodo
                    local meta = minetest.get_meta(pos)
                    local inv_node = meta:get_inventory()
                    if inv_node and not is_inv_empty(inv_node) then
                        for _, list in pairs(inv_node:get_lists()) do
                            for _, stack in ipairs(list) do
                                if not stack:is_empty() then
                                    inv_player:add_item("main", stack)
                                end
                            end
                        end
                    end

                    -- Bloquear los drops temporales en el motor
                    local real_handle = minetest.handle_node_drops
                    local real_drop = minetest.item_drop
                    minetest.handle_node_drops = function() end
                    minetest.item_drop = function() end

                    -- Picar el nodo (esto activa sonidos, partículas y desgaste nativo)
                    original_on_dig(pos, node, digger, ...)

                    -- Restaurar el motor
                    minetest.handle_node_drops = real_handle
                    minetest.item_drop = real_drop

                    -- Asegurar colección: 1 unidad del bloque al inventario del jugador
                    if inv_player and not inv_player:contains_item("main", node_name) then
                        inv_player:add_item("main", ItemStack(node_name .. " 1"))
                    end

                    return true
                end
            })
        end
    end
end)

-- 2. LA SUPER MANO (42/256)
local digtime = 42
local caps = {times = {digtime, digtime, digtime}, uses = 0, maxlevel = 256}

minetest.register_item("creative:super_hand", {
    type = "none",
    wield_image = "wieldhand.png",
    wield_scale = {x=1, y=1, z=2.5},
    range = 10,
    tool_capabilities = {
        full_punch_interval = 0.5,
        max_drop_level = 3,
        groupcaps = {
            crumbly = caps, cracky = caps, snappy = caps, choppy = caps,
            oddly_breakable_by_hand = caps,
            dig_immediate = {times = {[2] = digtime, [3] = 0}, uses = 0, maxlevel = 256},
        },
        damage_groups = {fleshy = 100},
    }
})

function creative_inventory.update_hand(player)
    local inv = player:get_inventory()
    if creative_inventory.is_creative(player) then
        inv:set_size("hand", 1)
        inv:set_stack("hand", 1, "creative:super_hand")
    else
        inv:set_size("hand", 0)
    end
end

-- 3. UI Y PRIVILEGIOS
local function update_everything(name)
    local player = minetest.get_player_by_name(name)
    if player then
        minetest.after(0, function()
            if creative_inventory.is_creative(player) then
                creative_inventory.set_creative_formspec(player, 0, 1)
            else
                creative_inventory.set_survival_formspec(player)
            end
            creative_inventory.update_hand(player)
        end)
    end
end

minetest.register_privilege("creative", {
    description = "Modo creativo",
    give_to_singleplayer = false,
    on_grant = update_everything,
    on_revoke = update_everything,
})

-- 4. INVENTARIO DETACHED (CATÁLOGO)
minetest.register_on_mods_loaded(function()
    local inv = minetest.create_detached_inventory("creative", {
        allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
            return creative_inventory.is_creative(player) and count or 0
        end,
        allow_take = function(inv, listname, index, stack, player)
            return creative_inventory.is_creative(player) and -1 or 0
        end,
        allow_put = function() return 0 end,
    })
    local creative_list = {}
    for name, def in pairs(minetest.registered_items) do
        if (not def.groups.not_in_creative_inventory or def.groups.not_in_creative_inventory == 0)
                and def.description and def.description ~= "" then
            table.insert(creative_list, name)
        end
    end
    table.sort(creative_list)
    inv:set_size("main", #creative_list)
    for _, item in ipairs(creative_list) do
        inv:add_item("main", ItemStack(item))
    end
    creative_inventory.creative_inventory_size = #creative_list
end)

local trash = minetest.create_detached_inventory("creative_trash", {
    allow_put = function(inv, listname, index, stack, player) return stack:get_count() end,
    on_put = function(inv, listname, index, stack, player) inv:set_stack(listname, index, "") end,
})
trash:set_size("main", 1)

-- 5. FORMSPECS
creative_inventory.set_creative_formspec = function(player, start_i, pagenum)
    local pagemax = math.max(1, math.ceil(creative_inventory.creative_inventory_size / 24))
    local formspec = "size[13,7.5]list[current_player;main;5,3.5;8,4;]" ..
        "list[current_player;craft;8,0;3,3;]list[current_player;craftpreview;12,1;1,1;]" ..
        "list[detached:creative;main;0.3,0.5;4,6;"..tostring(start_i).."]" ..
        "label[2.0,6.55;"..tostring(pagenum).."/"..tostring(pagemax).."]" ..
        "button[0.3,6.5;1.6,1;creative_prev;<<]button[2.7,6.5;1.6,1;creative_next;>>]" ..
        "label[5,1.5;Papelera:]list[detached:creative_trash;main;5,2;1,1;]"
    player:set_inventory_formspec(formspec)
end

creative_inventory.set_survival_formspec = function(player)
    local formspec = "size[8,8.5]list[current_player;main;0,4.5;8,4;]" ..
        "list[current_player;craft;3,0;3,3;]list[current_player;craftpreview;7,1;1,1;]" ..
        "list[detached:creative_trash;main;0,2;1,1;]label[0,1.5;Papelera:]"
    player:set_inventory_formspec(formspec)
end

-- 6. CALLBACKS
minetest.register_on_joinplayer(function(player)
    update_everything(player:get_player_name())
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if not creative_inventory.is_creative(player) then return end
    local formspec = player:get_inventory_formspec()
    local start_i = tonumber(string.match(formspec, "list%[detached:creative;main;.-;.-;(%d+)%]")) or 0
    if fields.creative_prev or fields.creative_next then
        if fields.creative_prev then start_i = math.max(0, start_i - 24)
        elseif fields.creative_next and (start_i + 24 < creative_inventory.creative_inventory_size) then
            start_i = start_i + 24
        end
        creative_inventory.set_creative_formspec(player, start_i, math.floor(start_i / 24) + 1)
    end
end)

minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack)
    if creative_inventory.is_creative(placer) then return true end
end)
