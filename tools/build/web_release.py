# Godot 4.6.2 Minification Profile for Trivia Dash
optimize = "size"
lto = "full"
debug_symbols = "no"

# Disable threading for GitHub Pages (avoid SharedArrayBuffer requirement)
threads = "no"

# Disable heavy features
disable_3d = "yes"
vulkan = "no"
opengl3 = "yes"
openxr = "no"
disable_advanced_gui = "yes"

# Module management
modules_enabled_by_default = "no"
module_gdscript_enabled = "yes"
module_text_server_fb_enabled = "yes"
module_freetype_enabled = "yes"
module_svg_enabled = "yes"
module_json_enabled = "yes"
module_regex_enabled = "yes"
module_wav_enabled = "yes"
