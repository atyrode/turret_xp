local label_colors = require("scripts.control.label_colors")
local bound_turret_items = require("scripts.control.bound_turret_items")

return function(M)
  setmetatable(M, { __index = _G })
  local _ENV = M

  local bound_turret_item_service = nil

  local function get_bound_turret_item_service()
    if not bound_turret_item_service then
      bound_turret_item_service = bound_turret_items.new({
        profile_tag = PROFILE_TAG,
        bound_turret_tag = BOUND_TURRET_TAG,
        base_turret_name = BASE_TURRET_NAME,
        normalize_profile = normalize_profile,
        serialize_profile = serialize_profile,
        deserialize_profile = deserialize_profile,
        copy_serializable = copy_serializable,
        profile_description_with_build = profile_description_with_build,
        quality_name_from_stack = quality_name_from_stack,
        get_bound_turret_item_name = get_bound_turret_item_name,
        is_bound_turret_item_name = is_bound_turret_item_name,
        remove_item_from_inventory = remove_item_from_inventory,
        spill_stack_definition = spill_stack_definition,
      })
    end

    return bound_turret_item_service
  end

  function create_blank_profile()
    return {
      xp = 0,
      total_xp = 0,
      level = 0,
      kills = 0,
      kill_credit = 0,
      damage = 0,
      xp_damage = 0,
      xp_kill_credit = 0,
      skills = {},
      evolution = {},
      chip_quality = "normal",
      custom_name = "",
      show_name_label = false,
      show_label_level = true,
      label_color = { 1, 0.86, 0.46 },
      label_color_preset = "gold",
      label_scale = 2,
      bound_turret = false,
      last_ammo = nil,
      ammo_regen_progress = 0,
    }
  end

  function normalize_profile(profile)
    if type(profile) ~= "table" then
      profile = create_blank_profile()
    end

    profile.xp = profile.xp or 0
    profile.total_xp = profile.total_xp or 0
    profile.level = math.max(0, math.floor(tonumber(profile.level) or 0))
    profile.kills = profile.kills or 0
    profile.kill_credit = profile.kill_credit or profile.kills or 0
    profile.damage = profile.damage or 0
    ensure_xp_counters(profile)
    profile.dev_xp = profile.dev_xp or 0
    profile.chip_quality = profile.chip_quality or "normal"
    profile.custom_name = profile.custom_name or ""
    profile.show_name_label = profile.show_name_label == true
    profile.show_label_level = profile.show_label_level ~= false
    profile.bound_turret = profile.bound_turret == true
    profile.ammo_regen_progress = math.max(0, tonumber(profile.ammo_regen_progress) or 0)
    if type(profile.last_ammo) == "table" and feeder.is_ammo_item(profile.last_ammo.name) then
      profile.last_ammo = {
        name = profile.last_ammo.name,
        quality = profile.last_ammo.quality or "normal",
      }
    else
      profile.last_ammo = nil
    end
    if type(profile.label_color) ~= "table" then
      profile.label_color = { 1, 0.86, 0.46 }
    end
    if profile.label_color_preset ~= "custom" and not label_colors.preset_by_id(profile.label_color_preset) then
      local preset = label_colors.preset_from_color(profile.label_color)
      profile.label_color_preset = preset and preset.id or "custom"
    end
    profile.label_scale = 2
    ensure_evolution_state(profile)
    sync_turret_progression(profile)
    return profile
  end

  function allocate_chip_id()
    ensure_storage()
    local id = "core-" .. tostring(storage.turret_xp.next_chip_id)
    storage.turret_xp.next_chip_id = storage.turret_xp.next_chip_id + 1
    return id
  end

  function get_turret_host(entity, create)
    if not is_gun_turret(entity) then
      return nil
    end

    ensure_storage()
    local key = turret_key(entity)
    local host = storage.turret_xp.turrets[key]

    if host and not host.chip_id and (host.evolution or host.skills or host.total_xp or host.damage or host.kills) then
      local profile = normalize_profile(host)
      profile.chip_id = profile.chip_id or allocate_chip_id()
      profile.entity = entity
      storage.turret_xp.chips[profile.chip_id] = profile
      host = {
        chip_id = profile.chip_id,
      }
      storage.turret_xp.turrets[key] = host
    end

    if not host and create then
      host = {}
      storage.turret_xp.turrets[key] = host
    end

    if host then
      host.entity = entity
    end

    return host
  end

  function get_installed_profile(entity)
    local host = get_turret_host(entity, false)
    if not host or not host.chip_id then
      return nil
    end

    local profile = storage.turret_xp.chips[host.chip_id]
    if not profile then
      host.chip_id = nil
      return nil
    end

    profile.chip_id = host.chip_id
    profile.entity = entity
    return normalize_profile(profile)
  end

  function get_turret_state(entity)
    return get_installed_profile(entity)
  end

  function remove_turret_state(entity, destroy_profile)
    if not is_gun_turret(entity) then
      return
    end

    ensure_storage()
    local key = turret_key(entity)
    local host = storage.turret_xp.turrets[key]
    if host and host.chip_id then
      local profile = storage.turret_xp.chips[host.chip_id]
      if profile then
        destroy_name_render(profile)
        destroy_selection_proxy(profile)
      end
      if destroy_profile then
        storage.turret_xp.chips[host.chip_id] = nil
      end
    end
    storage.turret_xp.turrets[key] = nil
  end

  function copy_serializable(value)
    if type(value) ~= "table" then
      return value
    end

    local result = {}
    for key, child in pairs(value) do
      local skip_runtime_key = type(key) == "string" and string.sub(key, 1, 1) == "_"
      if
        not skip_runtime_key
        and key ~= "entity"
        and key ~= "name_render"
        and key ~= "label_entity"
        and key ~= "selection_proxy"
        and key ~= "feeder"
      then
        result[key] = copy_serializable(child)
      end
    end
    return result
  end

  function serialize_profile(profile)
    profile = normalize_profile(profile)
    local evolution = ensure_evolution_state(profile)

    return {
      schema = 1,
      chip_id = profile.chip_id,
      chip_quality = profile.chip_quality or "normal",
      custom_name = profile.custom_name or "",
      show_name_label = profile.show_name_label == true,
      show_label_level = profile.show_label_level ~= false,
      bound_turret = profile.bound_turret == true,
      label_color = copy_serializable(profile.label_color or { 1, 0.86, 0.46 }),
      label_color_preset = profile.label_color_preset or "custom",
      label_scale = profile.label_scale or 2,
      xp = profile.xp or 0,
      total_xp = profile.total_xp or 0,
      level = profile.level or 0,
      kills = profile.kills or 0,
      kill_credit = profile.kill_credit or 0,
      damage = profile.damage or 0,
      xp_damage = profile.xp_damage or profile.damage or 0,
      xp_kill_credit = profile.xp_kill_credit or profile.kill_credit or 0,
      dev_xp = profile.dev_xp or 0,
      last_ammo = copy_serializable(profile.last_ammo),
      ammo_regen_progress = profile.ammo_regen_progress or 0,
      evolution = {
        base = copy_serializable(evolution.base or {}),
        augments = copy_serializable(evolution.augments or {}),
        element_mastery = copy_serializable(evolution.element_mastery or {}),
        elements = {
          evolution.elements and evolution.elements[1] or nil,
          evolution.elements and evolution.elements[2] or nil,
        },
        specialization = evolution.specialization,
        sub_specialization = evolution.sub_specialization,
        element_project = copy_serializable(evolution.element_project),
      },
    }
  end

  function deserialize_profile(data)
    local profile = create_blank_profile()
    if type(data) == "table" then
      profile.chip_id = data.chip_id
      profile.chip_quality = data.chip_quality or "normal"
      profile.custom_name = data.custom_name or ""
      profile.show_name_label = data.show_name_label == true
      profile.show_label_level = data.show_label_level ~= false
      profile.bound_turret = data.bound_turret == true
      profile.label_color = copy_serializable(data.label_color or { 1, 0.86, 0.46 })
      profile.label_color_preset = data.label_color_preset or nil
      profile.label_scale = data.label_scale or 2
      profile.xp = data.xp or 0
      profile.total_xp = data.total_xp or 0
      profile.level = data.level or 0
      profile.kills = data.kills or 0
      profile.kill_credit = data.kill_credit or data.kills or 0
      profile.damage = data.damage or 0
      profile.xp_damage = data.xp_damage
      profile.xp_kill_credit = data.xp_kill_credit
      profile.dev_xp = data.dev_xp or 0
      profile.last_ammo = copy_serializable(data.last_ammo)
      profile.ammo_regen_progress = data.ammo_regen_progress or 0
      profile.evolution = copy_serializable(data.evolution or {})
    end

    if type(profile.evolution) ~= "table" then
      profile.evolution = {}
    end

    return normalize_profile(profile)
  end

  function read_profile_from_chip_stack(stack)
    if not stack or not stack.valid_for_read or stack.name ~= CHIP_NAME then
      return nil
    end

    local data = compat.try("read core profile tag", function()
      return stack.get_tag(PROFILE_TAG)
    end)

    local profile = deserialize_profile(data)
    profile.chip_quality = compat.quality_name(stack, profile.chip_quality or "normal", "core stack quality")
    return normalize_profile(profile)
  end

  function profile_format_rank(rank)
    return tostring(math.max(0, math.floor(tonumber(rank) or 0)))
  end

  function profile_join(parts)
    if #parts == 0 then
      return nil
    end

    return table.concat(parts, ", ")
  end

  function profile_rank_list(definitions, ranks)
    local parts = {}
    ranks = type(ranks) == "table" and ranks or {}
    for _, definition in ipairs(definitions or {}) do
      local rank = math.max(0, math.floor(tonumber(ranks[definition.id]) or 0))
      if rank > 0 then
        parts[#parts + 1] = definition.name .. " r" .. profile_format_rank(rank)
      end
    end

    return profile_join(parts)
  end

  function profile_element_rank_caption(profile, evolution, element_id)
    local element = ELEMENT_BY_ID[element_id]
    if not element then
      return nil
    end

    local mastery = evolution.element_mastery and evolution.element_mastery[element_id] or nil
    local rank = mastery and math.max(0, math.floor(tonumber(mastery.rank) or 0)) or 0
    local caption = element.name .. " r" .. profile_format_rank(rank)
    local delivered, required, requirement = get_element_progress(profile, element_id)
    if requirement and required > 0 then
      caption = caption
        .. " ("
        .. profile_format_rank(delivered)
        .. "/"
        .. profile_format_rank(required)
        .. " [item="
        .. requirement.name
        .. "])"
    end
    return caption
  end

  function profile_elements_summary(profile, evolution)
    local parts = {}
    for slot = 1, 2 do
      local caption = profile_element_rank_caption(profile, evolution, evolution.elements and evolution.elements[slot] or nil)
      if caption then
        parts[#parts + 1] = caption
      end
    end

    return #parts > 0 and table.concat(parts, " + ") or nil
  end

  function profile_specialization_summary(evolution)
    local specialization = evolution.specialization and SPECIALIZATION_BY_ID[evolution.specialization] or nil
    if not specialization then
      return nil
    end

    local sub_specialization = evolution.sub_specialization and SUB_SPECIALIZATION_BY_ID[evolution.sub_specialization] or nil
    if sub_specialization and sub_specialization.parent == specialization.id then
      return specialization.name .. " / " .. sub_specialization.name
    end

    return specialization.name
  end

  function profile_build_lines(profile)
    profile = normalize_profile(profile)
    local evolution = ensure_evolution_state(profile)
    local lines = {}

    local specialization = profile_specialization_summary(evolution)
    if specialization then
      lines[#lines + 1] = { "", "[color=1,0.86,0.46]Spec:[/color] ", specialization }
    end

    local elements = profile_elements_summary(profile, evolution)
    if elements then
      lines[#lines + 1] = { "", "[color=0.35,0.75,1]Elements:[/color] ", elements }
    end

    local core = profile_rank_list(BASE_UPGRADES, evolution.base)
    if core then
      lines[#lines + 1] = { "", "[color=0.58,0.82,0.38]Core:[/color] ", core }
    end

    local augments = profile_rank_list(AUGMENTS, evolution.augments)
    if augments then
      lines[#lines + 1] = { "", "[color=0.35,0.75,1]Aug:[/color] ", augments }
    end

    return lines
  end

  function profile_description_with_build(base_description, profile)
    local lines = profile_build_lines(profile)
    if #lines == 0 then
      return base_description
    end

    local description = { "", base_description, "\n" }
    for index, line in ipairs(lines) do
      if index > 1 then
        description[#description + 1] = "\n"
      end
      description[#description + 1] = line
    end

    return description
  end

  function profile_description(profile)
    profile = normalize_profile(profile)
    local name = profile.custom_name or ""
    local base_description
    if name ~= "" then
      base_description = { "item-description.turret-xp-veteran-core-profile-named", name, profile.level or 0 }
    else
      base_description = { "item-description.turret-xp-veteran-core-profile", profile.level or 0 }
    end

    return profile_description_with_build(base_description, profile)
  end

  function make_chip_item_stack(profile)
    local serialized = serialize_profile(profile)
    return {
      name = CHIP_NAME,
      count = 1,
      quality = serialized.chip_quality or "normal",
      tags = {
        [PROFILE_TAG] = serialized,
      },
      custom_description = profile_description(serialized),
    }
  end

  function quality_name_from_stack(stack, fallback)
    return compat.quality_name(stack, fallback or "normal", "stack quality")
  end

  function quality_name_from_entity(entity, fallback)
    return compat.quality_name(entity, fallback or "normal", "entity quality")
  end

  function snapshot_turret_item_state(entity)
    local snapshot = {
      quality = quality_name_from_entity(entity, "normal"),
      health_ratio = 1,
      ammo = {},
    }
    if not is_gun_turret(entity) then
      return snapshot
    end

    local health = safe_read(entity, "health")
    local max_health = safe_read(entity, "max_health")
    if health and max_health and max_health > 0 then
      snapshot.health_ratio = math.max(0.01, math.min(1, health / max_health))
    end

    local inventory = feeder.get_entity_inventory(entity, defines.inventory.turret_ammo)
    if inventory then
      for index = 1, #inventory do
        local stack = inventory[index]
        if stack and stack.valid_for_read then
          snapshot.ammo[#snapshot.ammo + 1] = {
            name = stack.name,
            count = stack.count,
            quality = quality_name_from_stack(stack, "normal"),
          }
        end
      end
    end

    return snapshot
  end

  function clear_turret_ammo_inventory(entity)
    if not is_gun_turret(entity) then
      return
    end

    local inventory = feeder.get_entity_inventory(entity, defines.inventory.turret_ammo)
    if not inventory then
      return
    end

    for index = 1, #inventory do
      local stack = inventory[index]
      if stack then
        stack.clear()
      end
    end
  end

  function ammo_snapshot_key(name, quality)
    return tostring(name or "") .. "\n" .. tostring(quality or "normal")
  end

  function build_desired_turret_ammo_counts(snapshot)
    local desired = {}
    for _, ammo in ipairs((snapshot and snapshot.ammo) or {}) do
      local count = math.max(0, math.floor(tonumber(ammo.count) or 0))
      if ammo.name and count > 0 then
        local quality = ammo.quality or "normal"
        local key = ammo_snapshot_key(ammo.name, quality)
        desired[key] = desired[key] or {
          name = ammo.name,
          quality = quality,
          count = 0,
        }
        desired[key].count = desired[key].count + count
      end
    end
    return desired
  end

  function make_item_stack_definition(name, count, quality)
    local item = {
      name = name,
      count = count,
    }
    if quality and quality ~= "" then
      item.quality = quality
    end
    return item
  end

  function reconcile_preloaded_turret_ammo(entity, inventory, snapshot)
    local desired = build_desired_turret_ammo_counts(snapshot)
    if not inventory or not inventory.valid then
      return desired
    end

    -- Placement-helper mods can preload ammo before the bound turret profile is restored.
    -- Treat that ammo as external and refund it; the bound snapshot remains the source of truth.
    for index = 1, #inventory do
      local stack = inventory[index]
      if stack and stack.valid_for_read then
        local name = stack.name
        local quality = quality_name_from_stack(stack, "normal")
        local count = stack.count
        local removed = remove_item_from_inventory(inventory, make_item_stack_definition(name, count, quality))
        if removed > 0 then
          spill_stack_definition_at(entity.surface, entity.position, make_item_stack_definition(name, removed, quality))
        end
      end
    end

    return desired
  end

  function restore_turret_item_state(entity, snapshot)
    if not is_gun_turret(entity) or type(snapshot) ~= "table" then
      return
    end

    local max_health = safe_read(entity, "max_health")
    if max_health then
      entity.health = math.max(1, math.min(max_health, max_health * (snapshot.health_ratio or 1)))
    end

    local inventory = feeder.get_entity_inventory(entity, defines.inventory.turret_ammo)
    if not inventory then
      return
    end

    local remaining = reconcile_preloaded_turret_ammo(entity, inventory, snapshot)
    for _, ammo in pairs(remaining) do
      if ammo.name and (ammo.count or 0) > 0 then
        local item = make_item_stack_definition(ammo.name, ammo.count, ammo.quality or "normal")
        local inserted = compat.try("restore turret ammo", function()
          return inventory.insert(item)
        end, 0) or 0
        local overflow = (ammo.count or 0) - inserted
        if overflow > 0 then
          spill_stack_definition_at(
            entity.surface,
            entity.position,
            make_item_stack_definition(ammo.name, overflow, ammo.quality or "normal")
          )
        end
      end
    end
  end

  function bound_turret_description(profile)
    return get_bound_turret_item_service().description(profile)
  end

  function make_bound_turret_item_stack(profile, turret_snapshot)
    return get_bound_turret_item_service().make_stack(profile, turret_snapshot)
  end

  function read_bound_turret_stack(stack)
    return get_bound_turret_item_service().read_stack(stack)
  end

  function find_bound_turret_stack_in_inventory(inventory)
    return get_bound_turret_item_service().find_stack_in_inventory(inventory)
  end

  function get_bound_turret_stack_from_build_event(event)
    return get_bound_turret_item_service().stack_from_build_event(event)
  end

  function find_carried_chip_stack(player)
    local cursor_stack = player.cursor_stack
    if cursor_stack and cursor_stack.valid_for_read and cursor_stack.name == CHIP_NAME then
      return cursor_stack
    end

    local inventory = player.get_main_inventory()
    if not inventory or not inventory.valid then
      return nil
    end

    for index = 1, #inventory do
      local stack = inventory[index]
      if stack and stack.valid_for_read and stack.name == CHIP_NAME then
        return stack
      end
    end

    return nil
  end

  function remove_one_chip_stack(stack)
    if not stack or not stack.valid_for_read or stack.name ~= CHIP_NAME then
      return false
    end

    if stack.count and stack.count > 1 then
      stack.count = stack.count - 1
    else
      stack.clear()
    end
    return true
  end

  function insert_chip_item(player, profile)
    local stack = make_chip_item_stack(profile)
    local can_insert = compat.try("player can_insert core", function()
      return player.can_insert(stack)
    end, false)

    if not can_insert then
      return false
    end

    local inserted = player.insert(stack)
    return inserted and inserted > 0
  end

  function can_insert_chip_inventory(inventory, profile)
    if not inventory or not inventory.valid then
      return false
    end

    local stack = make_chip_item_stack(profile)
    local can_insert = compat.try("inventory can_insert core", function()
      return inventory.can_insert(stack)
    end, false)

    if not can_insert then
      return false
    end

    return true
  end

  get_platform_hub_inventory = function(entity)
    if not is_gun_turret(entity) then
      return nil
    end

    return compat.platform_hub_inventory(entity, defines.inventory.hub_main)
  end

  function get_platform_core_options(entity)
    local options = {}
    local inventory = get_platform_hub_inventory(entity)
    if not inventory then
      return options
    end

    for index = 1, #inventory do
      local stack = inventory[index]
      if stack and stack.valid_for_read and stack.name == CHIP_NAME then
        options[#options + 1] = {
          index = index,
          quality = quality_name_from_stack(stack, "normal"),
          profile = read_profile_from_chip_stack(stack),
        }
      end
    end

    return options
  end

  function spill_chip_item(entity, profile)
    if not entity or not entity.valid then
      return false
    end

    local ok = compat.try("spill core item", function()
      entity.surface.spill_item_stack({
        position = entity.position,
        stack = make_chip_item_stack(profile),
        enable_looted = true,
        allow_belts = false,
      })
      return true
    end, false)

    return ok
  end

  function spill_stack_definition(entity, stack)
    if not entity or not entity.valid or not stack or not stack.name or (stack.count or 0) <= 0 then
      return false
    end

    return spill_stack_definition_at(entity.surface, entity.position, stack)
  end

  function spill_stack_definition_at(surface, position, stack)
    if not surface or not position or not stack or not stack.name or (stack.count or 0) <= 0 then
      return false
    end

    local ok = compat.try("spill stack definition", function()
      surface.spill_item_stack({
        position = position,
        stack = stack,
        enable_looted = true,
        allow_belts = false,
      })
      return true
    end, false)
    return ok
  end

  function remove_item_from_inventory(inventory, item)
    if not inventory or not inventory.valid or not item or not item.name or (item.count or 0) <= 0 then
      return 0
    end

    local removed = compat.try("inventory remove item", function()
      return inventory.remove(item)
    end, 0)
    if removed and removed > 0 then
      return removed
    end

    local fallback = {
      name = item.name,
      count = item.count,
    }
    removed = compat.try("inventory remove fallback item", function()
      return inventory.remove(fallback)
    end, 0)
    return removed or 0
  end

  function remove_bound_turret_mining_results(buffer, turret_snapshot)
    get_bound_turret_item_service().remove_mining_results(buffer, turret_snapshot)
  end

  function insert_bound_turret_item(inventory, entity, profile, turret_snapshot)
    return get_bound_turret_item_service().insert_item(inventory, entity, profile, turret_snapshot)
  end

  function pending_bound_key(entity)
    return entity_tracking_key(entity)
  end

  destroy_name_render = function(profile)
    if profile and profile.name_render and profile.name_render.valid then
      profile.name_render.destroy()
    end
    if profile and profile.label_entity and profile.label_entity.valid then
      pcall(function()
        profile.label_entity.destroy({ raise_destroy = false })
      end)
    end
    if profile then
      profile.name_render = nil
      profile.label_entity = nil
    end
  end

  function find_matching_label_color_preset(profile)
    if not profile then
      return nil
    end

    if profile.label_color_preset and profile.label_color_preset ~= "custom" then
      local preset = label_colors.preset_by_id(profile.label_color_preset)
      if preset then
        return preset
      end
    end

    if profile.label_color_preset == "custom" then
      return nil
    end

    return label_colors.preset_from_color(profile.label_color)
  end

  function get_label_panel_name(profile)
    local preset = find_matching_label_color_preset(profile)
    if preset then
      return LABEL_PANEL_PREFIX .. preset.id
    end

    local color = profile and profile.label_color or { 1, 0.86, 0.46 }
    local function quantize(value)
      return math.max(0, math.min(LABEL_CUSTOM_COLOR_STEPS, math.floor((tonumber(value) or 0) * LABEL_CUSTOM_COLOR_STEPS + 0.5)))
    end
    return LABEL_PANEL_PREFIX
      .. "custom-"
      .. tostring(quantize(color[1]))
      .. "-"
      .. tostring(quantize(color[2]))
      .. "-"
      .. tostring(quantize(color[3]))
  end

  function get_profile_label_text(profile)
    profile = normalize_profile(profile)
    local name = profile.custom_name or ""
    if name == "" then
      return nil
    end

    if profile.show_label_level == false then
      return name
    end

    return name .. " (lvl " .. tostring(profile.level or 0) .. ")"
  end

  function update_name_render(entity, profile)
    if not profile then
      return
    end

    if not is_gun_turret(entity) or not profile.show_name_label then
      destroy_name_render(profile)
      return
    end

    local text = get_profile_label_text(profile)
    if not text then
      destroy_name_render(profile)
      return
    end

    local label_panel_name = get_label_panel_name(profile)
    if label_panel_name and prototypes.entity[label_panel_name] then
      if profile.name_render and profile.name_render.valid then
        profile.name_render.destroy()
        profile.name_render = nil
      end

      if
        profile.label_entity
        and profile.label_entity.valid
        and profile.label_entity.name == label_panel_name
        and profile.label_entity.surface == entity.surface
      then
        local ok = pcall(function()
          profile.label_entity.teleport(entity.position, entity.surface)
          profile.label_entity.force = entity.force
          profile.label_entity.display_panel_text = text
          profile.label_entity.display_panel_always_show = true
          profile.label_entity.display_panel_show_in_chart = false
          profile.label_entity.display_panel_icon = nil
        end)
        if ok then
          return
        end
      end

      if profile.label_entity and profile.label_entity.valid then
        pcall(function()
          profile.label_entity.destroy({ raise_destroy = false })
        end)
        profile.label_entity = nil
      end

      local ok, label_entity = pcall(function()
        return entity.surface.create_entity({
          name = label_panel_name,
          position = entity.position,
          force = entity.force,
          raise_built = false,
          create_build_effect_smoke = false,
        })
      end)

      if ok and label_entity then
        pcall(function()
          label_entity.destructible = false
        end)
        pcall(function()
          label_entity.minable_flag = false
        end)
        pcall(function()
          label_entity.operable = false
        end)
        pcall(function()
          label_entity.rotatable = false
        end)
        pcall(function()
          label_entity.display_panel_text = text
          label_entity.display_panel_always_show = true
          label_entity.display_panel_show_in_chart = false
          label_entity.display_panel_icon = nil
        end)
        profile.label_entity = label_entity
        return
      end
    elseif profile.label_entity and profile.label_entity.valid then
      pcall(function()
        profile.label_entity.destroy({ raise_destroy = false })
      end)
      profile.label_entity = nil
    end

    if profile.name_render and profile.name_render.valid then
      local ok = pcall(function()
        profile.name_render.text = text
        profile.name_render.target = {
          entity = entity,
          offset = { 0, -2.05 },
        }
        profile.name_render.surface = entity.surface
        profile.name_render.forces = { entity.force }
        profile.name_render.color = profile.label_color or { 1, 0.86, 0.46 }
        profile.name_render.scale = profile.label_scale or 2
      end)
      if ok then
        return
      end
      destroy_name_render(profile)
    end

    local ok, render_object = pcall(function()
      return rendering.draw_text({
        text = text,
        surface = entity.surface,
        target = {
          entity = entity,
          offset = { 0, -2.05 },
        },
        color = profile.label_color or { 1, 0.86, 0.46 },
        scale = profile.label_scale or 2,
        font = "default-bold",
        alignment = "center",
        vertical_alignment = "middle",
        scale_with_zoom = true,
        only_in_alt_mode = false,
        forces = { entity.force },
      })
    end)

    if ok then
      profile.name_render = render_object
    end
  end

  function chip_id_is_installed(chip_id)
    if not chip_id then
      return false
    end

    ensure_storage()
    for _, host in pairs(storage.turret_xp.turrets) do
      if host and host.chip_id == chip_id then
        return true
      end
    end

    return false
  end

  function install_profile_on_turret(entity, profile)
    if not is_gun_turret(entity) then
      return nil
    end

    ensure_storage()
    local host = get_turret_host(entity, true)
    if host.chip_id then
      return nil
    end

    profile = normalize_profile(profile)
    if not profile.chip_id or chip_id_is_installed(profile.chip_id) or storage.turret_xp.chips[profile.chip_id] then
      profile.chip_id = allocate_chip_id()
    end

    profile.entity = entity
    storage.turret_xp.chips[profile.chip_id] = profile
    host.chip_id = profile.chip_id
    feeder.ensure(entity, profile)
    ensure_selection_proxy(entity, profile)
    update_name_render(entity, profile)
    return profile
  end

  function detach_profile_from_turret(entity)
    local profile = get_installed_profile(entity)
    if not profile then
      return nil
    end

    local chip_id = profile.chip_id
    destroy_name_render(profile)
    destroy_selection_proxy(profile)
    feeder.destroy(profile, entity.position, true)
    profile.entity = nil
    if chip_id then
      storage.turret_xp.chips[chip_id] = nil
    end

    local host = get_turret_host(entity, false)
    if host then
      host.chip_id = nil
    end

    return profile
  end
end
