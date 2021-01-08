config =
    modlib.conf.import(
    "playertags",
    {
        type = "table",
        children = {
            glow = {
                type = "number",
                range = {0, 15}
            },
            size = {
                type = "number",
                range = {0}
            },
            step = {
                type = "number",
                range = {0}
            }
        }
    }
)
modlib.table.add_all(getfenv(1), config)
y_size = size * (64 / 48)

function generate_texture(s)
    local r = "playertag_bg.png^[resize:" .. tostring(string.len(s) * 48) .. "x64"
    for i = 1, string.len(s) do
        local char = "freemono_" .. string.byte(s, i) .. ".png"
        r = r .. "^[combine:64x64:" .. tostring((i - 1) * 48) .. ",0" .. "=" .. char
    end
    return r
end

function generate_player_texture(player)
    return generate_texture(player:get_player_name()) .. "^[multiply:" .. modlib.player.get_color(player)
end

function attach_tag(tag, player)
    tag:set_attach(player, "", {x = 0, y = (player:get_properties().collisionbox[5] + y_size) * 10, z = 0}, {x = 0, y = 180, z = 0})
end

function get_visual_size(name)
    return {
        y = y_size,
        x = size * name:len(),
        z = 1
    }
end

function make_nametag_invisible(player)
    local color = player:get_nametag_attributes().color
    color.a = 0
    player:set_nametag_attributes{
        -- Empty nametag in order to counter poorly made hacked clients
        text = "",
        color = color
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