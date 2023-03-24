var script_class = "tool"

# Set to true to show debug buttons
const DEBUG_MODE = false
# Constants holding the names for the meta options
const LEVEL_VISIBILITY_META = "permanent_level_visibility"
const LEVEL_ID_META = "level_id"
const REWIND_ICON_PATH = "icons/rewind_icon.png"

# Id of the last selected level in Global.World
var previous_level_id: int = 0
# The tree for the level visibility UI
var tree = null
var current_level_hash: String = ""
var tool_enabled = false
var tool_panel = null


# Vanilla start function called by Dungeondraft when the mod is first loaded
func start():
    # Fetch tool panel for level selection.
    tool_panel = Global.Editor.Toolset.GetToolPanel("LevelSettings")

    tool_panel.BeginSection(true)

    # If in DEBUG_MODE, print buttons for:
    # Debug button that prints a lot of useful information
    # Refresh button that refreshes the level visibility UI
    if DEBUG_MODE:
        var debug_button = tool_panel.CreateButton("DEBUG", Global.Root + REWIND_ICON_PATH)
        debug_button.connect("pressed", self, "_on_debug_button")

        var refresh_button = tool_panel.CreateButton("Refresh Visibility", Global.Root + REWIND_ICON_PATH)
        refresh_button.connect("pressed", self, "refresh_visibility_tool_tree")
    
    # Create a new UI tree layout
    # The tree is not yet populated as this needs to be done anew every time the levels update
    tree = Tree.new()
    tree.set_h_size_flags(3)
    tree.set_v_size_flags(3)
    tool_panel.Align.add_child(tree)

    tool_panel.EndSection()

    # Connect signals
    tree.connect("item_edited", self, "_on_tree_button_toggled")
    tool_panel.connect("visibility_changed", self, "_on_tool_visibility_changed")


# Vanilla update called by Godot every frame.
# We only need to refresh the tool layout if the tool is enabled.
# While we could do this on a timer, I do not think that the performance overhead matters much on this tool.
# Regardless of whether the tool is active or not, we need to update the visibility of a level after swapping levels.
func update(delta):
    if tool_enabled:
        refresh_visibility_tool_tree()
    
    update_old_level_visibility()


# Detects whether the tool is active based on its visibility.
# This is a terrible hack and I deserve to be eaten by a dragon.
func _on_tool_visibility_changed():
    tool_enabled = tool_panel.visible
    #print("Tool status: %s" % tool_enabled)


# Called whenever a check_button on the permanent visibility menu is toggled.
# Updates the permanent_level_visibility flag of the level associated with that check_button to match
# Finally updates the corresponding level to match its flag
func _on_tree_button_toggled ():
    var tree_item = tree.get_edited()
    if not tree_item.has_meta(LEVEL_ID_META):
        return

    var level_id = tree_item.get_meta(LEVEL_ID_META)
    Global.World.levels[level_id].set_meta(LEVEL_VISIBILITY_META, tree_item.is_checked(0))
    if level_id != Global.World.CurrentLevelId:
        set_level_visible(level_id, tree_item.is_checked(0))


# If the level layout has changed, updates the visibility selection tree to match
func refresh_visibility_tool_tree():
    # Only refresh the visibility bar if the level layout actually changed since the last refresh.
    var new_level_hash = hash_levels()
    if new_level_hash == current_level_hash:
        #print("No Visibility Refresh (%s)" % current_level_hash)
        return
    current_level_hash = new_level_hash
    #print("Refresh Visibility (%s)" % current_level_hash)
    
    # Clears the tree and sets up the root of the tree
    # The root also serves as a label for the tree
    tree.clear()
    var root = tree.create_item()
    root.set_text(0, "Permanently Visible Levels")
    root.set_selectable(0, false)
    
    # Adds the individual checkboxes for the visibility selection tree
    var i = 0;
    for level in Global.World.levels:
        var new_item = tree.create_item(root)
        new_item.set_cell_mode(0, 1)
        new_item.set_editable(0, true)
        new_item.set_selectable(0, false)
        new_item.set_text(0, level.Label)
        new_item.set_meta(LEVEL_ID_META, i)
        if (
                level.has_meta(LEVEL_VISIBILITY_META)
                and level.get_meta(LEVEL_VISIBILITY_META)
        ):
            new_item.set_checked(0, true)
            set_level_visible(i)
        i += 1
    previous_level_id = Global.World.CurrentLevelId


# Returns a hash of the level layout.
# The hash should be different every time a level is:
# created   and added to the Global.World tree
# deleted   or removed from the Global.World tree
# moved     to a different order in the Global.World tree
# renamed   with a different display label
func hash_levels():
    var hash_content = ""
    for level in Global.World.levels:
        hash_content += str(level.get_instance_id())
        hash_content += str(level.Label)
    return hash_content


# If the active level has been changed since the last call,
# changes the previously selected level's visibility to the one assigned by this mod.
func update_old_level_visibility():
    var current_level_id = Global.World.CurrentLevelId
    if current_level_id == previous_level_id:
        return
    
    var previous_level = Global.World.levels[previous_level_id]
    if (
            previous_level.has_meta(LEVEL_VISIBILITY_META)
            and previous_level.get_meta(LEVEL_VISIBILITY_META)
    ):
        set_level_visible(previous_level_id)
    
    # When DD sets a world visible, it resets the z layer index to 0.
    # So push it up to the intended value again.
    set_z_level(current_level_id)
    previous_level_id = current_level_id


# Used to set the given level to become visible
func set_level_visible(level_id = 0, is_visible = true):
    var level = Global.World.levels[level_id]
    level.visible = is_visible
    set_z_level(level_id)


# Changes the z-index of the level.
# The minimum and maximum allowed by Godot are -4096 and 4096 respectively, so we are limited in what we have available to us.
# Dungeondraft burns 1500 layers per level, so they were shortened to 1000.
# One side effect of this is the ground of a higher level being on the same layer as the roofs on the level below.
# We can also have at most 9 levels active at a time before Godot limits us.
# Currently I deal with this limit by overflowing back to -4000.
# This may inconvenience the user, but will have to stay until a smarter solution is found.
func set_z_level(level_id = 0):
    var level = Global.World.levels[level_id]
    level.z_index = 4000 - level_id % 9 * 1000






# =========================================================
# ANYTHING BEYOND THIS POINT IS FOR DEBUGGING PURPOSES ONLY
# =========================================================



# Debug function, very important. Prints whatever stuff I need to know at the moment.
func _on_debug_button():
    print("========== DEBUG BUTTON ==========")
    print_levels()
    print_methods(Global.World)
    print_properties(Global.World)
    print_signals(Global.World)
    Global.World.print_tree_pretty()


# Debug function, prints out the info for every level
func print_levels():
    for level in Global.World.levels:
        print("==== Level %s ====" % level.name)
        print("Z Index: %s" % level.z_index)
        print("Z Relative: %s" % level.z_as_relative)



# Debug function, prints properties of the given node
func print_properties(node):
    print("========= PRINTING PROPERTIES OF %s ==========" % node.name)
    var properties_list = node.get_property_list()
    for property in properties_list:
        print(property.name)


# Debug function, prints methods of the given node
func print_methods(node):
    print("========= PRINTING METHODS OF %s ==========" % node.name)
    var method_list = node.get_method_list()
    for method in method_list:
        print(method.name)


# Debug function, prints signals of the given node
func print_signals(node):
    print("========= PRINTING SIGNALS OF %s ==========" % node.name)
    var signal_list = node.get_signal_list()
    for sig in signal_list:
        print(sig.name)