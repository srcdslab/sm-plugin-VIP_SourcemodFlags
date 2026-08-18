# Copilot Instructions for VIP SourceMod Flags Plugin

## Repository Overview

This repository contains a SourceMod plugin written in SourcePawn that manages VIP user flags and permissions in Source engine game servers. The plugin integrates with VIP-Core to automatically assign admin flags and groups to VIP users, providing them with appropriate permissions and immunity levels.

**Key Features:**
- Automatic admin flag assignment for VIP users
- Dynamic group creation and management
- Integration with SourceBans++ for admin cache management
- Support for Custom Chat Colors (CCC) integration
- Configurable VIP group names and immunity levels

## Technical Environment

**Language**: SourcePawn (.sp files)
**Platform**: SourceMod 1.12+
**Build System**: Native GitHub Actions (rumblefrog/setup-sp)
**Compiler**: SourceMod compiler (spcomp) - installed and run by the CI workflow

### Dependencies
- **sourcemod**: Core SourceMod framework (version 1.11.0-git6917)
- **vip_core**: VIP system core functionality
- **multicolors**: Color chat message support
- **utilshelper**: Utility functions
- **ccc** (optional): Custom Chat Colors integration
- **sourcebanspp** (optional): SourceBans++ integration

## Build System

### GitHub Actions Configuration
The project builds via `.github/workflows/ci.yml`:
- SourceMod compiler (spcomp) is installed via `rumblefrog/setup-sp@v1.3.1` pinned to SourceMod 1.12.x
- Git dependencies (CustomChatColors, VIP-Core, sourcebans-pp, UtilsHelper) are cloned and their include files copied into `addons/sourcemod/scripting/include`
- Output directory: `addons/sourcemod/plugins`
- Target plugin: `VIP_SourcemodFlags`

### Building the Plugin
The plugin is built automatically by CI on every push/PR. To build locally, install a SourcePawn compiler matching SourceMod 1.12.x, place the dependency include files under `addons/sourcemod/scripting/include`, then run:
```bash
spcomp -i include -o ../plugins/VIP_SourcemodFlags.smx VIP_SourcemodFlags.sp
```

### CI/CD Pipeline
The repository uses native GitHub Actions (`.github/workflows/ci.yml`):
- Automatically builds on push/PR to any branch
- Creates releases for tagged versions and latest ("latest" tag) builds on master/main

## Code Style & Standards

### SourcePawn Conventions
- **Indentation**: Use tabs (equivalent to 4 spaces)
- **Variables**: 
  - Local variables and parameters: `camelCase`
  - Global variables: `PascalCase` with `g_` prefix (e.g., `g_cvVIPGroupName`)
  - Functions: `PascalCase`
- **Pragmas**: Always include `#pragma semicolon 1` and `#pragma newdecls required`
- **Memory Management**: Use `delete` for cleanup, avoid `.Clear()` on StringMap/ArrayList

### File Structure
```
addons/sourcemod/scripting/
├── VIP_SourcemodFlags.sp    # Main plugin file
└── include/                 # Include files (dependencies)
```

## Plugin Architecture

### Core Components
1. **VIP Integration**: Hooks into VIP-Core events for user status changes
2. **Admin Management**: Dynamic creation/removal of admin entries
3. **Group Management**: Automatic VIP group creation with proper flags
4. **Optional Integrations**: SourceBans++ and Custom Chat Colors support

### Key Functions
- `LoadVIPClient(client)`: Assigns admin flags to VIP users
- `UnloadVIPClient(client)`: Removes admin flags from non-VIP users
- `LoadClient(client)`: Core logic for admin flag assignment
- `RemoveClient(client)`: Core logic for admin flag removal

### Configuration Variables
- `sm_vip_group_name`: VIP group name (default: "VIP")
- `sm_vip_group_immunity`: Immunity level for VIP users (default: 5, range: 0-100)

## Development Guidelines

### Adding New Features
1. **Follow existing patterns**: Use the same event handling structure
2. **Memory management**: Always use `delete` for cleanup, never check for null before delete
3. **Error handling**: Validate client indices and states before operations
4. **Integration**: Use optional includes for external dependencies (`#tryinclude`)

### Common Modifications
- **Adding new VIP flags**: Modify the group creation logic in `LoadClient()`
- **Changing immunity logic**: Update `SetAdmGroupImmunityLevel()` calls
- **Adding integrations**: Follow the CCC/SourceBans++ pattern with library checks

### Testing Procedures
1. **Build validation**: Ensure plugin compiles without warnings
2. **Server testing**: Test on a development server with VIP-Core installed
3. **Integration testing**: Verify compatibility with optional dependencies
4. **Memory testing**: Check for memory leaks using SourceMod's profiler

## Working with Dependencies

### Required Dependencies
All required dependencies are cloned and copied in the `.github/workflows/ci.yml` "Install dependencies" step. When adding new dependencies:
1. Add a `git clone` + `cp` block for the new dependency in `.github/workflows/ci.yml`
2. Update the include statements in the plugin file
3. Test the build process

### Optional Dependencies
Optional dependencies use conditional compilation:
```sourcepawn
#undef REQUIRE_PLUGIN
#tryinclude <optional_plugin>
#define REQUIRE_PLUGIN

// Later in code:
#if defined _optional_plugin_included
    // Optional functionality
#endif
```

## Common Tasks

### Adding a New ConVar
```sourcepawn
// In OnPluginStart()
ConVar g_cvNewSetting = CreateConVar("sm_vip_new_setting", "default", "Description");
```

### Adding Admin Commands
```sourcepawn
// In OnPluginStart()
RegAdminCmd("sm_newcommand", Command_NewCommand, ADMFLAG_BAN);

public Action Command_NewCommand(int client, int args)
{
    // Command implementation
    return Plugin_Handled;
}
```

### Debugging Tips
- Use `CPrintToChat()` for colored debug messages
- Check `IsValidClient()` before client operations
- Monitor server logs for compilation and runtime errors
- Use the `sm_adminimmunity` command to verify immunity levels

## File Locations

- **Plugin source**: `addons/sourcemod/scripting/VIP_SourcemodFlags.sp`
- **CI/CD**: `.github/workflows/ci.yml`
- **Compiled output**: `addons/sourcemod/plugins/VIP_SourcemodFlags.smx`

## Best Practices

1. **Always validate client indices** before performing operations
2. **Use meaningful variable names** that reflect their purpose
3. **Document complex logic** with inline comments
4. **Test with multiple scenarios**: VIP addition, removal, server restart, plugin reload
5. **Handle edge cases**: Client disconnection during admin operations
6. **Optimize performance**: Avoid unnecessary loops in frequently called functions
7. **Memory safety**: Always clean up StringMaps and ArrayLists with `delete`
8. **Version compatibility**: Ensure changes work with minimum SourceMod version (1.11+)

## Troubleshooting

### Build Issues
- Verify all dependencies are cloned in the `.github/workflows/ci.yml` "Install dependencies" step
- Check for syntax errors using SourceMod compiler warnings
- Ensure proper include file placement

### Runtime Issues
- Check SourceMod error logs for detailed error messages
- Verify VIP-Core is properly installed and functioning
- Test admin cache rebuilding with `sm_reloadadmins`
- Use `sm_reloadvips` command to refresh VIP admin assignments

### Integration Issues
- Verify optional dependencies are properly detected with library checks
- Test with and without optional plugins loaded
- Check for proper event handling order with other plugins