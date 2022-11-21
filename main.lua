modlib.table.add_all(getfenv(1), modlib.mod.configuration())
y_size = size * (64 / 48)

function generate_texture(s)
    local w = tostring(#s * 48)
    local r = "playertag_bg.png^[resize:" .. w .. "x64^[combine:" .. w .. "x64"
    for i = 1, #s do
        local char = "freemono_" .. s:byte(i) .. ".png"
        r = r .. ":" .. tostring((i - 1) * 48) .. ",0" .. "=" .. char
    end
    return r
end

function generate_player_texture(player)
    return generate_texture(player:get_player_name()) .. "^[multiply:"
        .. modlib.minetest.colorspec.new(player:get_nametag_attributes().color):to_string()
end

function attach_tag(tag, player)
    tag:set_attach(player, "", {x = 0, y = (player:get_properties().collisionbox[5] + y_size) * 10, z = 0}, {x = 0, y = 180, z = 0})
end

function get_visual_size(name)
    return {
        y = y_size,
        x = size * #name,
        z = 1
    }
end

function make_nametag_invisible(player)
    local nametag_attrs = player:get_nametag_attributes()
    local color, bgcolor = nametag_attrs.color, nametag_attrs.bgcolor or {r = 0, g = 0, b = 0, a = 0}
    color.a, bgcolor.a = 0, 0
    player:set_nametag_attributes{
        -- Null nametag in order to counter poorly made hacked clients (isn't empty, but won't be rendered)
        text = "\0",
        color = color,
        bgcolor = bgcolor
    }
end

if size > 0 then
    minetest.register_entity(
        "playertags:playertag",
        {
            initial_properties = {
                max_hp = 1,
                physical = false,
                collide_with_objects = false,
                pointable = false,
                use_texture_alpha = true,
                is_invisible = true,
                visual = "sprite",
                visual_size = {x = 1, y = 1, z = 1},
                textures = {"freemono_30.png"},
                collisionbox = {0, 0, 0, 0, 0, 0},
                selectionbox = {0, 0, 0, 0, 0, 0},
                glow = glow
            },
            on_step = function(self, dtime)
                self.timer = self.timer + dtime
                if self.timer >= step then
                    if not self.owner then
                        self.object:remove()
                        return
                    end
                    self.timer = 0
                    local owner = minetest.get_player_by_name(self.owner)
                    if not owner then
                        self.object:remove()
                        return
                    end
                    if owner:get_properties().is_invisible then
                        self.object:set_properties({visual_size = {x = 0, y = 0}, is_invisible = true})
                    else
                        local props = {
                            visual_size = get_visual_size(self.owner)
                        }
                        local color = owner:get_properties().nametag_color
                        if owner:get_properties().nametag_color.a ~= 0 then
                            make_nametag_invisible(owner)
                        end
                        local rgb = minetest.rgba(color.r, color.g, color.b)
                        if self.color ~= rgb then
                            self.color = rgb
                            props.textures = {generate_player_texture(owner)}
                        end
                        self.object:set_properties(props)
                    end
                    if not self.object:get_attach() ~= self.owner then
                        attach_tag(self.object, owner)
                    end
                end
            end,
            on_activate = function(self, dtime)
                self.timer = 0
                self.object:set_armor_groups({immortal = 1})
            end
        }
    )
    minetest.register_on_joinplayer(
        function(player)
            make_nametag_invisible(player)
            local pos = player:get_pos()
            pos.y = player:get_properties().collisionbox[5] + y_size
            local tag = minetest.add_entity(pos, "playertags:playertag")
            tag:get_luaentity().owner = player:get_player_name()
            tag:set_properties(
                {
                    visual_size = get_visual_size(player:get_player_name()),
                    textures = {generate_player_texture(player)}
                }
            )
            attach_tag(tag, player)
        end
    )
else
    minetest.register_on_joinplayer(
        function(player)
            make_nametag_invisible(player)
        end
    )
    modlib.minetest.register_globalstep(step, function()
        for _, player in pairs(minetest.get_connected_players()) do
            make_nametag_invisible(player)
        end
    end)
end
