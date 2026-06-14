local gui_support = require("scripts.control.gui_support")
local gui_components = require("scripts.control.gui_components")
local gui_formatters = require("scripts.control.gui.formatters")
local gui_core_panel = require("scripts.control.gui.core_panel")
local gui_core_identity = require("scripts.control.gui.core_identity")
local gui_core_label_controls = require("scripts.control.gui.core_label_controls")
local gui_core_platform_controls = require("scripts.control.gui.core_platform_controls")
local gui_stats_panel = require("scripts.control.gui.stats_panel")
local gui_evolution_panel = require("scripts.control.gui.evolution_panel")
local gui_shell = require("scripts.control.gui.shell")
local gui_runtime = require("scripts.control.gui.runtime")
local gui_widgets = require("scripts.control.gui.widgets")
local gui_core_picker_table = require("scripts.control.gui.core_picker_table")

return function(M)
  setmetatable(M, { __index = _G })
  local _ENV = M

  local gui_support_service = nil
  local gui_components_service = nil
  local gui_formatters_service = nil
  local core_panel_service = nil
  local core_identity_service = nil
  local core_label_controls_service = nil
  local stats_panel_service = nil
  local evolution_panel_service = nil
  local shell_service = nil
  local runtime_service = nil
  local widgets_service = nil
  local core_picker_table_service = nil

  local function get_shell_service()
    if not shell_service then
      shell_service = gui_shell.new({
        GUI = GUI,
        LAYOUT = LAYOUT,
        set_style = set_style,
      })
    end

    return shell_service
  end

  local function get_gui_support_service()
    if not gui_support_service then
      gui_support_service = gui_support.new({
        COLOR = COLOR,
        LAYOUT = LAYOUT,
        format_number = format_number,
        set_style = set_style,
      })
    end

    return gui_support_service
  end

  local function get_gui_components_service()
    if not gui_components_service then
      gui_components_service = gui_components.new({
        COLOR = COLOR,
        LAYOUT = LAYOUT,
        rich_color = function(color, text)
          return rich_color(color, text)
        end,
        set_evolution_content_width = function(element, inner)
          return set_evolution_content_width(element, inner)
        end,
        set_style = set_style,
        with_info_marker = with_info_marker,
      })
    end

    return gui_components_service
  end

  local function get_gui_widgets_service()
    if not widgets_service then
      widgets_service = gui_widgets.new({
        set_style = set_style,
      })
    end

    return widgets_service
  end

  local function get_core_picker_table_service()
    if not core_picker_table_service then
      core_picker_table_service = gui_core_picker_table.new({
        GUI = GUI,
        COLOR = COLOR,
        LAYOUT = LAYOUT,
        set_style = set_style,
        widgets = get_gui_widgets_service(),
      })
    end

    return core_picker_table_service
  end

  local function get_core_identity_service()
    if not core_identity_service then
      core_identity_service = gui_core_identity.new({
        GUI = GUI,
        LAYOUT = LAYOUT,
        CHIP_NAME = CHIP_NAME,
        set_style = set_style,
        set_element_style = set_element_style,
        dev_controls_enabled = dev_controls_enabled,
        widgets = get_gui_widgets_service(),
      })
    end

    return core_identity_service
  end

  local function get_core_label_controls_service()
    if not core_label_controls_service then
      core_label_controls_service = gui_core_label_controls.new({
        GUI = GUI,
        set_style = set_style,
        find_matching_label_color_preset = find_matching_label_color_preset,
      })
    end

    return core_label_controls_service
  end

  local function get_gui_formatters_service()
    if not gui_formatters_service then
      gui_formatters_service = gui_formatters.new({
        COLOR = COLOR,
        ELEMENT_BY_ID = ELEMENT_BY_ID,
        apply_luck_to_chance = apply_luck_to_chance,
        ensure_evolution_state = ensure_evolution_state,
        format_number = format_number,
        format_percent = function(value, decimals)
          return get_gui_support_service().format_percent(value, decimals)
        end,
        rich_color = function(color, text)
          return get_gui_support_service().rich_color(color, text)
        end,
        color_to_rich_string = function(color)
          return get_gui_support_service().color_to_rich_string(color)
        end,
      })
    end

    return gui_formatters_service
  end

  local function get_core_panel_service()
    if not core_panel_service then
      core_panel_service = gui_core_panel.new({
        GUI = GUI,
        COLOR = COLOR,
        LAYOUT = LAYOUT,
        CHIP_NAME = CHIP_NAME,
        set_style = set_style,
        set_element_style = set_element_style,
        find_gui_element = find_gui_element,
        get_remembered_turret = get_remembered_turret,
        get_player_core_options = get_player_core_options,
        get_player_core_options_model = get_player_core_options_model,
        get_core_picker_sort = get_core_picker_sort,
        get_core_picker_filters = get_core_picker_filters,
        core_picker_filters_key = core_picker_filters_key,
        get_platform_core_options = get_platform_core_options,
        get_platform_hub_inventory = get_platform_hub_inventory,
        create_blank_profile = create_blank_profile,
        dev_controls_enabled = dev_controls_enabled,
        update_name_render = update_name_render,
        ensure_evolution_state = ensure_evolution_state,
        get_specialization = get_specialization,
        get_sub_specialization = get_sub_specialization,
        get_loaded_ammo = get_loaded_ammo,
        get_entity_quality_name = get_entity_quality_name,
        get_max_health_for_quality = get_max_health_for_quality,
        get_health_formula_values = get_health_formula_values,
        get_shooting_speed_formula_values = get_shooting_speed_formula_values,
        get_range_formula_values = get_range_formula_values,
        format_number = format_number,
        SPECIALIZATIONS = SPECIALIZATIONS,
        rich_value = function(value, suffix, color)
          return rich_value(value, suffix, color)
        end,
        rich_metric = function(label, value, suffix, color)
          return rich_metric(label, value, suffix, color)
        end,
        rich_specialization_caption = function(specialization_id, caption)
          return get_gui_support_service().rich_specialization_caption(specialization_id, caption)
        end,
        widgets = get_gui_widgets_service(),
        core_picker_table = get_core_picker_table_service(),
        core_identity = get_core_identity_service(),
        core_label_controls = get_core_label_controls_service(),
        core_platform_controls = gui_core_platform_controls,
      })
    end

    return core_panel_service
  end

  local function get_stats_panel_service()
    if not stats_panel_service then
      stats_panel_service = gui_stats_panel.new({
        GUI = GUI,
        COLOR = COLOR,
        LAYOUT = LAYOUT,
        add_stat_row = add_stat_row,
        make_stats_table = make_stats_table,
        set_style = set_style,
        set_element_style = set_element_style,
        find_gui_element = find_gui_element,
        format_number = format_number,
        format_percent = format_percent,
        rich_number = rich_number,
        rich_stat_text = rich_stat_text,
        rich_color = rich_color,
        color_to_rich_string = color_to_rich_string,
        rich_specialization_caption = function(specialization_id, caption)
          return get_gui_support_service().rich_specialization_caption(specialization_id, caption)
        end,
        format_colored_multiplier = format_colored_multiplier,
        format_stat_formula = format_stat_formula,
        get_base_rank = get_base_rank,
        get_ammo_productivity_fraction = get_ammo_productivity_fraction,
        get_effective_ammo_productivity_fraction = get_effective_ammo_productivity_fraction,
        get_sub_specialization_flat_bonus = get_sub_specialization_flat_bonus,
        get_luck_multiplier = get_luck_multiplier,
        get_crit_chance_fraction = get_crit_chance_fraction,
        get_crit_damage_formula_values = get_crit_damage_formula_values,
        get_augment_rank = get_augment_rank,
        get_shield_on_hit_fraction = get_shield_on_hit_fraction,
        get_lifesteal_rate = get_lifesteal_rate,
        apply_luck_to_chance = apply_luck_to_chance,
        get_double_shot_chance = get_double_shot_chance,
        get_unique_active_element_ids = get_unique_active_element_ids,
        get_element_rank = get_element_rank,
        get_element_effect_summary_for_rank = get_element_effect_summary_for_rank,
        element_name = element_name,
        ensure_evolution_state = ensure_evolution_state,
        get_combo_caption = get_combo_caption,
        get_specialization = get_specialization,
        get_sub_specialization = get_sub_specialization,
        make_quality_tooltip = make_quality_tooltip,
        get_max_health_for_quality = get_max_health_for_quality,
        get_health_formula_values = get_health_formula_values,
        get_repair_per_second = get_repair_per_second,
        get_repair_base_per_second = get_repair_base_per_second,
        get_specialization_multiplier = get_specialization_multiplier,
        normalize_shield_state = normalize_shield_state,
        get_shield_recharge_per_second = get_shield_recharge_per_second,
        get_damage_resistance_fraction = get_damage_resistance_fraction,
        get_shooting_speed_formula_values = get_shooting_speed_formula_values,
        format_shots_per_second = format_shots_per_second,
        format_range_for_quality = format_range_for_quality,
        get_range_formula_values = get_range_formula_values,
        format_range = format_range,
        get_damage_formula_values = get_damage_formula_values,
        format_damage_per_shot = format_damage_per_shot,
        get_estimated_dps_values = get_estimated_dps_values,
        format_estimated_dps_formula = format_estimated_dps_formula,
      })
    end

    return stats_panel_service
  end

  local function get_evolution_panel_service()
    if not evolution_panel_service then
      evolution_panel_service = gui_evolution_panel.new({
        GUI = GUI,
        COLOR = COLOR,
        LAYOUT = LAYOUT,
        GATES = GATES,
        BASE_UPGRADES = BASE_UPGRADES,
        AUGMENTS = AUGMENTS,
        ELEMENTS = ELEMENTS,
        ELEMENT_BY_ID = ELEMENT_BY_ID,
        SPECIALIZATIONS = SPECIALIZATIONS,
        SPECIALIZATION_BY_ID = SPECIALIZATION_BY_ID,
        SUB_SPECIALIZATIONS_BY_PARENT = SUB_SPECIALIZATIONS_BY_PARENT,
        SUB_SPECIALIZATION_BY_ID = SUB_SPECIALIZATION_BY_ID,
        set_style = set_style,
        set_element_style = set_element_style,
        find_gui_element = find_gui_element,
        scroll_evolution_to_anchor = scroll_evolution_to_anchor,
        evolution_anchor_name = evolution_anchor_name,
        format_number = format_number,
        rich_number = rich_number,
        rich_stat_text = rich_stat_text,
        set_evolution_content_width = set_evolution_content_width,
        set_card_text_width = set_card_text_width,
        set_evolution_card_child_width = set_evolution_card_child_width,
        get_gui_components_service = get_gui_components_service,
        ensure_evolution_state = ensure_evolution_state,
        get_sub_specialization = get_sub_specialization,
        get_available_skill_points = get_available_skill_points,
        get_available_augment_points = get_available_augment_points,
        get_base_rank = get_base_rank,
        get_augment_rank = get_augment_rank,
        get_element_progress = get_element_progress,
        get_element_effect_summary = get_element_effect_summary,
        element_name = element_name,
        get_combo_caption = get_combo_caption,
        get_combo_caption_for_pair = get_combo_caption_for_pair,
        get_element_effect_summary_for_rank = get_element_effect_summary_for_rank,
        specialization_effect_entries = specialization_effect_entries,
        sub_specialization_effect_entries = sub_specialization_effect_entries,
        specialization_effect_value_caption = specialization_effect_value_caption,
      })
    end

    return evolution_panel_service
  end

  local function get_gui_runtime_service()
    if not runtime_service then
      runtime_service = gui_runtime.new({
        GUI = GUI,
        get_gui_panel = get_gui_panel,
        get_turret_state = get_turret_state,
        sync_turret_progression = sync_turret_progression,
        get_loaded_ammo = get_loaded_ammo,
        get_entity_quality_name = get_entity_quality_name,
        safe_read = safe_read,
        get_max_health_for_quality = get_max_health_for_quality,
        set_gui_caption = set_gui_caption,
        set_gui_progress = set_gui_progress,
        format_number = format_number,
        update_core_panel = function(...)
          return update_core_panel(...)
        end,
        update_stats_panel = function(...)
          return update_stats_panel(...)
        end,
        update_evolution_panel = function(...)
          return update_evolution_panel(...)
        end,
        update_shield_bar_render = update_shield_bar_render,
      })
    end

    return runtime_service
  end

  function add_stat_row(parent, label, element_name, options)
    return get_gui_components_service().add_stat_row(parent, label, element_name, options)
  end

  function make_stats_table(parent, name)
    return get_gui_components_service().make_stats_table(parent, name)
  end

  function add_summary_label(parent, title, value, value_color)
    return get_gui_components_service().add_summary_label(parent, title, value, value_color)
  end

  function add_choice_delimiter(parent)
    return get_gui_components_service().add_choice_delimiter(parent)
  end

  function add_row(parent, sprite, name, detail, right_caption, tags, enabled, row_name)
    return get_gui_components_service().add_choice_row(parent, sprite, name, detail, right_caption, tags, enabled, row_name)
  end

  function add_section(parent, title, unlocked, gate_level, right_caption, action_caption, action_tags, action_tooltip, action_enabled)
    return get_evolution_panel_service().add_section(
      parent,
      title,
      unlocked,
      gate_level,
      right_caption,
      action_caption,
      action_tags,
      action_tooltip,
      action_enabled
    )
  end

  function format_percent(value, decimals)
    return get_gui_support_service().format_percent(value, decimals)
  end

  function color_to_rich_string(color)
    return get_gui_support_service().color_to_rich_string(color)
  end

  function rich_number(text, color)
    return get_gui_support_service().rich_number(text, color)
  end

  function rich_value(value, suffix, color)
    return get_gui_support_service().rich_value(value, suffix, color)
  end

  function rich_metric(label, value, suffix, color)
    return get_gui_support_service().rich_metric(label, value, suffix, color)
  end

  function rich_stat_text(text, color)
    return get_gui_support_service().rich_stat_text(text, color)
  end

  function rich_color(color, text)
    return get_gui_support_service().rich_color(color, text)
  end

  function rich_specialization_caption(specialization_id, caption)
    return get_gui_support_service().rich_specialization_caption(specialization_id, caption)
  end

  function set_evolution_content_width(element, inner)
    get_gui_support_service().set_evolution_content_width(element, inner)
  end

  function set_card_text_width(element)
    get_gui_support_service().set_card_text_width(element)
  end

  function set_evolution_card_child_width(element)
    get_gui_support_service().set_evolution_card_child_width(element)
  end

  function element_name(element_id)
    return get_gui_formatters_service().element_name(element_id)
  end

  function get_combo_caption(state)
    return get_gui_formatters_service().get_combo_caption(state)
  end

  function get_combo_caption_for_pair(first, second)
    return get_gui_formatters_service().get_combo_caption_for_pair(first, second)
  end

  function get_element_proc_chance_for_rank(state, rank)
    return get_gui_formatters_service().get_element_proc_chance_for_rank(state, rank)
  end

  function get_element_multiplier_for_rank(rank)
    return get_gui_formatters_service().get_element_multiplier_for_rank(rank)
  end

  function get_element_arc_count_for_rank(rank)
    return get_gui_formatters_service().get_element_arc_count_for_rank(rank)
  end

  function get_element_effect_summary_for_rank(state, element_id, rank, rich, color_terms)
    return get_gui_formatters_service().get_element_effect_summary_for_rank(state, element_id, rank, rich, color_terms)
  end

  function format_effect_percent(value, decimals)
    return get_gui_formatters_service().format_effect_percent(value, decimals)
  end

  function format_multiplier_effect_percent(multiplier)
    return get_gui_formatters_service().format_multiplier_effect_percent(multiplier)
  end

  function effect_percent_for_entry(entry)
    return get_gui_formatters_service().effect_percent_for_entry(entry)
  end

  function build_specialization_effect_entries(entries)
    return get_gui_formatters_service().build_specialization_effect_entries(entries)
  end

  function specialization_effect_entries(specialization, entity, state, ammo_name)
    return get_gui_formatters_service().specialization_effect_entries(specialization, entity, state, ammo_name)
  end

  function sub_specialization_effect_entries(sub_specialization, entity, state, ammo_name)
    return get_gui_formatters_service().sub_specialization_effect_entries(sub_specialization, entity, state, ammo_name)
  end

  function specialization_effect_value_caption(entry)
    return get_gui_formatters_service().specialization_effect_value_caption(entry)
  end

  function add_xp_panel(parent)
    return get_core_panel_service().add_xp_panel(parent)
  end

  function build_gui_shell(player, mode)
    return get_shell_service().build(player, mode)
  end

  function add_core_panel(parent, mode)
    return get_core_panel_service().add_core_panel(parent, mode)
  end

  function core_panel_key(player, state)
    return get_core_panel_service().core_panel_key(player, state)
  end

  function add_platform_core_list(core_panel, entity, state)
    return get_core_panel_service().add_platform_core_list(core_panel, entity, state)
  end

  function add_inventory_core_picker(core_panel, player, entity)
    return get_core_panel_service().add_inventory_core_picker(core_panel, player, entity)
  end

  function prepare_inventory_core_options_for_display(entity, options, sort_mode)
    return get_core_panel_service().prepare_core_options_for_display(entity, options, sort_mode)
  end

  function add_dev_controls_panel(parent, player)
    return get_core_panel_service().add_dev_controls_panel(parent, player)
  end

  function update_core_panel(root, player, entity, state)
    return get_core_panel_service().update_core_panel(root, player, entity, state)
  end

  function render_ammo_productivity(parent, state)
    return get_stats_panel_service().render_ammo_productivity(parent, state)
  end

  function render_magazine_stack_flow(flow, ammo_name, ammo_count, ammo_quality)
    return get_stats_panel_service().render_magazine_stack_flow(flow, ammo_name, ammo_count, ammo_quality)
  end

  function render_current_ammo_flow(flow, ammo_in_magazine, ammo_magazine_size)
    return get_stats_panel_service().render_current_ammo_flow(flow, ammo_in_magazine, ammo_magazine_size)
  end

  function update_ammo_row(panel, ammo_name, ammo_count, ammo_quality, ammo_in_magazine, ammo_magazine_size, state)
    return get_stats_panel_service().update_ammo_row(
      panel,
      ammo_name,
      ammo_count,
      ammo_quality,
      ammo_in_magazine,
      ammo_magazine_size,
      state
    )
  end

  function add_stats_panel(parent)
    return get_stats_panel_service().add_stats_panel(parent)
  end

  function add_stat_value(stats, label, value, tooltip)
    return get_stats_panel_service().add_stat_value(stats, label, value, tooltip)
  end

  function add_custom_stat(stats, label, value, tooltip)
    return get_stats_panel_service().add_custom_stat(stats, label, value, tooltip)
  end

  function stat_formula_tooltip(description, formula)
    return get_stats_panel_service().stat_formula_tooltip(description, formula)
  end

  function add_stat_value_with_quality_marker(stats, label, value, info_tooltip, quality_tooltip)
    return get_stats_panel_service().add_stat_value_with_quality_marker(stats, label, value, info_tooltip, quality_tooltip)
  end

  function format_final_stat_value(total, base, suffix, decimals)
    return get_stats_panel_service().format_final_stat_value(total, base, suffix, decimals)
  end

  function formula_total_caption(values, suffix, decimals)
    return get_stats_panel_service().formula_total_caption(values, suffix, decimals)
  end

  function add_base_crit_stats(stats, state)
    return get_stats_panel_service().add_base_crit_stats(stats, state)
  end

  function format_bonus_value_with_multiplier(value, multiplier, suffix, decimals, numeric_suffix)
    return get_stats_panel_service().format_bonus_value_with_multiplier(value, multiplier, suffix, decimals, numeric_suffix)
  end

  function add_active_custom_stats(stats, state, entity)
    return get_stats_panel_service().add_active_custom_stats(stats, state, entity)
  end

  function update_stats_panel(
    panel,
    entity,
    state,
    ammo_name,
    ammo_count,
    ammo_quality,
    ammo_in_magazine,
    ammo_magazine_size,
    quality_name,
    max_health,
    health
  )
    return get_stats_panel_service().update_stats_panel(
      panel,
      entity,
      state,
      ammo_name,
      ammo_count,
      ammo_quality,
      ammo_in_magazine,
      ammo_magazine_size,
      quality_name,
      max_health,
      health
    )
  end

  function add_specialization_effect_table(parent, entries)
    return get_evolution_panel_service().add_specialization_effect_table(parent, entries)
  end

  function add_evolution_panel(parent)
    return get_evolution_panel_service().add_evolution_panel(parent)
  end

  function has_level(state, level)
    return get_evolution_panel_service().has_level(state, level)
  end

  function update_evolution_summary(panel, state)
    return get_evolution_panel_service().update_evolution_summary(panel, state)
  end

  function add_element_choice_card(parent, element, state, slot)
    return get_evolution_panel_service().add_element_choice_card(parent, element, state, slot)
  end

  function add_allocation_row(parent, sprite, name, rank_caption, value_caption, button_caption, tags, enabled, tooltip, row_name)
    return get_evolution_panel_service().add_allocation_row(
      parent,
      sprite,
      name,
      rank_caption,
      value_caption,
      button_caption,
      tags,
      enabled,
      tooltip,
      row_name
    )
  end

  function add_base_allocation_row(parent, upgrade, rank, can_increase)
    return get_evolution_panel_service().add_base_allocation_row(parent, upgrade, rank, can_increase)
  end

  function add_rank_stepper(parent, rank, decrease_tags, increase_tags, can_decrease, can_increase, decrease_tooltip, increase_tooltip)
    return get_evolution_panel_service().add_rank_stepper(
      parent,
      rank,
      decrease_tags,
      increase_tags,
      can_decrease,
      can_increase,
      decrease_tooltip,
      increase_tooltip
    )
  end

  function add_augment_allocation_row(parent, augment, rank, available, at_max)
    return get_evolution_panel_service().add_augment_allocation_row(parent, augment, rank, available, at_max)
  end

  function add_element_mastery_panel(parent, state, element_id)
    return get_evolution_panel_service().add_element_mastery_panel(parent, state, element_id)
  end

  function add_base_section(parent, state)
    return get_evolution_panel_service().add_base_section(parent, state)
  end

  function add_element_choices(section, state, slot)
    return get_evolution_panel_service().add_element_choices(section, state, slot)
  end

  function add_first_element_section(parent, state)
    return get_evolution_panel_service().add_first_element_section(parent, state)
  end

  function add_specialization_choice_card(parent, anchor_name, sprite, name, description, effects, selected, action_tags)
    return get_evolution_panel_service().add_specialization_choice_card(
      parent,
      anchor_name,
      sprite,
      name,
      description,
      effects,
      selected,
      action_tags
    )
  end

  function add_specialization_option(parent, specialization, selected, entity, state, ammo_name)
    return get_evolution_panel_service().add_specialization_option(parent, specialization, selected, entity, state, ammo_name)
  end

  function add_specialization_section(parent, state, entity, ammo_name)
    return get_evolution_panel_service().add_specialization_section(parent, state, entity, ammo_name)
  end

  function add_sub_specialization_option(parent, sub_specialization, selected, entity, state, ammo_name)
    return get_evolution_panel_service().add_sub_specialization_option(parent, sub_specialization, selected, entity, state, ammo_name)
  end

  function add_sub_specialization_section(parent, state, entity, ammo_name)
    return get_evolution_panel_service().add_sub_specialization_section(parent, state, entity, ammo_name)
  end

  function add_augments_section(parent, state)
    return get_evolution_panel_service().add_augments_section(parent, state)
  end

  function add_second_element_section(parent, state)
    return get_evolution_panel_service().add_second_element_section(parent, state)
  end

  function update_evolution_panel(panel, entity, state, ammo_name, anchor_name)
    return get_evolution_panel_service().update_evolution_panel(panel, entity, state, ammo_name, anchor_name)
  end

  function update_turret_gui_stats(player, entity)
    return get_gui_runtime_service().update_turret_gui_stats(player, entity)
  end

  function update_turret_gui(player, entity, evolution_anchor)
    return get_gui_runtime_service().update_turret_gui(player, entity, evolution_anchor)
  end
end
