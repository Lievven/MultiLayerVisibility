var script_class = "tool"

func start():
    var category = "Terrain"
    var id = "lievven_test_tool"
    var name = "Lievven's Test Tool"
    var icon = Global.Root + "icons/stolen_tool_image.png"
    
    var tool_panel = Global.Editor.Toolset.CreateModTool(
        self, category, id, name, icon)
    tool_panel.CreateLabel("Tool Section")

    var button1 = tool_panel.CreateButton(
        "Show Dialog Box", Global.Root + "icons/stolen_tool_image.png")
    button1.connect("pressed", self, "show_diolog_box")
    
    var button2 = tool_panel.CreateButton(
        "Do nothing", Global.Root + "icons/stolen_tool_image.png")
    button2.connect("pressed", self, "do_nothing")





func do_nothing():
    pass


func show_dialog_box():
    OS.alert("Display message here.", "Title")