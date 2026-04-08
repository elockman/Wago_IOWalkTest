#!/usr/bin/env python3
"""
Import IO Walk Test structured text files into a CODESYS v3.5 project.

Usage:
    Run from CODESYS IDE: Tools -> Scripting -> Execute Script File
    Or from command line: CODESYS.exe --runscript import_to_codesys.py --project <path>

Prerequisites:
    - A CODESYS v3.5 project must be open with a WAGO 750-8212 PFC200 device configured
    - The Application object must exist under the device
"""

import os
import sys

# Base path — adjust if running from a different location
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)

# File manifest organized by CODESYS object type
MANIFEST = {
    "DUT": {
        "folder": "DUTs",
        "files": [
            ("E_TestState.st",   "E_TestState"),
            ("E_TestResult.st",  "E_TestResult"),
            ("E_ContactType.st", "E_ContactType"),
            ("E_AOPhase.st",     "E_AOPhase"),
            ("ST_DIChannel.st",  "ST_DIChannel"),
            ("ST_DOChannel.st",  "ST_DOChannel"),
            ("ST_AIChannel.st",  "ST_AIChannel"),
            ("ST_AOChannel.st",  "ST_AOChannel"),
        ],
    },
    "GVL": {
        "folder": "GVLs",
        "files": [
            ("GVL_HardwareIO.st",  "GVL_HardwareIO"),
            ("GVL_IOWalkTest.st",  "GVL_IOWalkTest"),
        ],
    },
    "FB": {
        "folder": "FBs",
        "files": [
            ("FB_DITest.st", "FB_DITest"),
            ("FB_DOTest.st", "FB_DOTest"),
            ("FB_AITest.st", "FB_AITest"),
            ("FB_AOTest.st", "FB_AOTest"),
        ],
    },
    "Program": {
        "folder": "Programs",
        "files": [
            ("PRG_IOWalkTest.st", "PRG_IOWalkTest"),
        ],
    },
}

# CODESYS object type GUIDs
CODESYS_TYPES = {
    "DUT":     "{2db5746a-b284-4571-9e4d-6e1d1d7f45f3}",  # DUT
    "GVL":     "{ffbfa93a-b94d-45fc-a329-229860183b1d}",  # GVL
    "FB":      "{2db5746a-b284-4571-9e4d-6e1d1d7f45f3}",  # POU (FB)
    "Program": "{2db5746a-b284-4571-9e4d-6e1d1d7f45f3}",  # POU (Program)
}

# Folder type GUID
FOLDER_GUID = "{738bea1e-99bb-4f04-90bb-a7a567e74e3a}"


def read_st_file(category, filename):
    """Read a .st file from the project directory."""
    filepath = os.path.join(PROJECT_ROOT, MANIFEST[category]["folder"], filename)
    with open(filepath, "r", encoding="utf-8") as f:
        return f.read()


def find_application(project):
    """Find the Application object in the project tree."""
    for device in project.active_application.parent:
        pass
    # Walk the device tree to find Application
    app = project.active_application
    if app is None:
        raise RuntimeError("No active application found. Open a project with a device and application first.")
    return app


def get_or_create_folder(parent, folder_name):
    """Get an existing folder or create a new one under parent."""
    for child in parent.get_children(False):
        if child.get_name(False) == folder_name:
            return child
    return parent.create_folder(folder_name)


def import_object(parent, name, source_code, obj_type):
    """Import a structured text object into the CODESYS project."""
    # Check if object already exists
    for child in parent.get_children(False):
        if child.get_name(False) == name:
            print(f"  Updating existing: {name}")
            # Remove and re-create to update
            child.remove()
            break

    if obj_type == "DUT":
        obj = parent.create_dut(name)
    elif obj_type == "GVL":
        obj = parent.create_gvl(name)
    elif obj_type == "FB":
        obj = parent.create_pou(name, pou_type=PouType.FunctionBlock,
                                language=ImplementationLanguages.ST)
    elif obj_type == "Program":
        obj = parent.create_pou(name, pou_type=PouType.Program,
                                language=ImplementationLanguages.ST)
    else:
        raise ValueError(f"Unknown object type: {obj_type}")

    # Set the textual declaration and implementation
    obj.textual_declaration.replace(source_code)
    print(f"  Imported: {name}")
    return obj


def main():
    print("=" * 60)
    print("IO Walk Test — CODESYS v3.5 Import Script")
    print("=" * 60)

    # Check if running inside CODESYS scripting engine
    try:
        proj = projects.primary
    except NameError:
        print("\nERROR: This script must be run from within the CODESYS IDE")
        print("       Tools -> Scripting -> Execute Script File")
        print("\nAlternatively, use the standalone export script:")
        print("       python3 export_xml.py")
        sys.exit(1)

    app = find_application(proj)
    print(f"Target application: {app.get_name(False)}")

    # Import order matters — DUTs first (dependencies), then GVLs, FBs, Programs
    import_order = ["DUT", "GVL", "FB", "Program"]

    for category in import_order:
        info = MANIFEST[category]
        folder_name = info["folder"]
        print(f"\n--- {folder_name} ---")

        # Create folder in project
        folder = get_or_create_folder(app, folder_name)

        for filename, obj_name in info["files"]:
            source = read_st_file(category, filename)
            try:
                import_object(folder, obj_name, source, category)
            except Exception as e:
                print(f"  FAILED: {obj_name} — {e}")

    # Add PRG_IOWalkTest to a task
    print("\n--- Task Configuration ---")
    try:
        task_config = None
        for child in app.get_children(True):
            if "TaskConfiguration" in str(type(child)):
                task_config = child
                break

        if task_config is not None:
            # Create or find a task for the walk test
            task_name = "IOWalkTest_Task"
            task_found = False
            for child in task_config.get_children(False):
                if child.get_name(False) == task_name:
                    task_found = True
                    print(f"  Task '{task_name}' already exists")
                    break

            if not task_found:
                print(f"  NOTE: Create task '{task_name}' manually:")
                print(f"        Type: Cyclic, Interval: T#20ms")
                print(f"        Add PRG_IOWalkTest as the program call")
        else:
            print("  No TaskConfiguration found — configure tasks manually")
    except Exception as e:
        print(f"  Task config skipped: {e}")

    print("\n" + "=" * 60)
    print("Import complete!")
    print("=" * 60)
    print("\nNext steps:")
    print("  1. Verify all objects compiled without errors")
    print("  2. Configure task: IOWalkTest_Task (Cyclic, T#20ms)")
    print("  3. Add PRG_IOWalkTest to the task")
    print("  4. Map IO variables in GVL_HardwareIO to device IO mapping")
    print("  5. Initialize channel config arrays in FB_DITest, FB_DOTest, etc.")


if __name__ == "__main__":
    main()
