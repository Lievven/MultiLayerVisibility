var script_class = "tool"

var tool_enabled = false
var previous_level_id = 0
var button = null
var tool_panel = null
var refresh_button = null

var current_level_hash = ""
var level_tree = null

# The tree for the UI and its root
var tree = null


func start():
    # Fetch tool panel for level selection.
    tool_panel = Global.Editor.Toolset.GetToolPanel("LevelSettings")

    # Add button for debug purposes. All this one does is display the active level on the button.
    button = tool_panel.CreateButton("Level ID", Global.Root + "icons/stolen_tool_image.png")
    button.connect("pressed", self, "_get_active_level")

    # Add button for debug print
    var debug_button = tool_panel.CreateButton("DEBUG", Global.Root + "icons/stolen_tool_image.png")
    debug_button.connect("pressed", self, "_on_debug_button")

    tool_panel.BeginSection(true)
    
    # Add a refresh button for debug purposes. This should clear and refresh the level order.
    refresh_button = tool_panel.CreateButton("Refresh Visibility", Global.Root + "icons/stolen_tool_image.png")
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
    tool_panel.connect("gui_input", self, "_on_gui_event")
    tool_panel.connect("visibility_changed", self, "_on_tool_visibility_changed")


# Detects whether the tool is active based on its visibility.
# This is a terrible hack and I deserve to be eaten by a dragon.
func _on_tool_visibility_changed():
    tool_enabled = tool_panel.visible
    print("Tool status: %s" % tool_enabled)


# Debug function, very important. Prints whatever stuff I need to know at the moment.
func _on_debug_button():
    print("========== DEBUG BUTTON ==========")
    #print_levels()
    #print_methods(Global.World)
    #print_properties(Global.World)
    #print_signals(Global.World.get_child("Level a"))
    #Global.World.print_tree_pretty()
    #tool_panel.Align.print_tree_pretty()
    #Global.World.print_tree_pretty()
    #print_methods(Global.World.levels[0])
    #print("Hash: %s" % hash_levels())
    #print_properties(tool_panel)


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
        hash_content = hash_content + level.get_instance_id()
    return hash_content


# Called whenever a check_button on the permanent visibility menu is toggled.
# Updates the permanent_level_visibility flag of the level associated with the check_button to match
# Finally updates the corresponding level to match its flag
func _on_tree_button_toggled ():
    print("==============BUTTON TOGGLED============")
    var tree_item = tree.get_edited()
    if not tree_item.has_meta("level_id"):
        return

    var level_id = tree_item.get_meta("level_id")
    print("Meta %s" % level_id)
    Global.World.levels[level_id].set_meta("permanent_level_visibility", tree_item.is_checked(0))
    if level_id != Global.World.Currentlevel_id:
        go_to_level(level_id, tree_item.is_checked(0))


# Vanilla update called by Godot every frame.
# We only need to refresh the tool layout if the tool is enabled.
# While we could do this on a timer, I do not think that the performance overhead matters much on this tool.
# Regardless of whether the tool is active or not, we need to update the visibility of a level after swapping levels.
func update(delta):
    if tool_enabled:
        pass
        #refresh_visibility_tool_tree()
    
    update_old_level_visibility()


func refresh_visibility_tool_tree():
    # Only refresh the visibility bar if the level layout actually changed since the last refresh.
    var new_level_hash = hash_levels()
    if new_level_hash == current_level_hash:
        print("No Visibility Refresh (%s)" % current_level_hash)
        return
    current_level_hash = new_level_hash
    
    print("Refresh Visibility (%s)" % current_level_hash)

    tree.clear()
    var root = tree.create_item()
    root.set_text(0, "Permanently Visible Levels")
    root.set_selectable(0, false)

    for level in Global.World.levels:
        var new_item = tree.create_item(root)
        new_item.set_cell_mode(0, 1)
        new_item.set_editable(0, true)
        new_item.set_selectable(0, false)
        new_item.set_text(0, level.Label)
        new_item.set_meta("level_id", level.ID)
        if level.get_meta("permanent_level_visibility"):
            new_item.set_checked(0, true)


# If the active level has been changed since the last call,
# changes the previously selected level's visibility to the one assigned by this mod.
func update_old_level_visibility():
    if Global.World.Currentlevel_id == previous_level_id:
        return
    
    var level_visibility_meta = Global.World.levels[previous_level_id].get_meta("permanent_level_visibility")
    if level_visibility_meta:
        go_to_level(previous_level_id)

    previous_level_id = Global.World.Currentlevel_id



# Sets the given level to become visible
func go_to_level(level_id = 0, is_visible = true):
    var level = Global.World.GetLevelByID(level_id)
    print("Go to level: %s with visibility: %s" % level % level.visible)
    level.visible = is_visible










# Debug function, prints out the info for every level
func print_levels():
    var i=0
    var level = Global.World.GetLevelByID(i)
    while level != null:
        print("Level: %s" % level)
        level.print_tree_pretty()
        i = i+1
        level = Global.World.GetLevelByID(i)


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


# Debug function, prints single node with a debug message.
# Meant for signal connection only
func _on_event_interaction(node):
    print("Event Interaction: %s" % node)


# Debug function, prints & displays the currently active level.
func _get_active_level():
    print("select level id: %s" % Global.World.Currentlevel_id)
    button.set_text("Level ID: %s" % Global.World.Currentlevel_id)


# Debug function, prints info about a node and all its children.
func check_children(node):
    for child in node.get_children():
        check_node(child)
        print("And children: {")
        check_children(child)
        print("}")


# Debug function, prints some info about node.
func check_node(node):
    print("Name: %s" % node.name)
    print("Path: %s" % node.get_path())
    print("With class: %s" % node.get_class())