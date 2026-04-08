#!/usr/bin/env python3
"""
Export IO Walk Test .st files to PLCopen XML format for import into CODESYS v3.5.

This script can run standalone (no CODESYS IDE required). It generates a single
PLCopen XML file that can be imported via: Project -> Import PLCopen XML...

Usage:
    python3 export_xml.py [--output path/to/output.xml]
"""

import os
import sys
import argparse
import re
import xml.etree.ElementTree as ET
from datetime import datetime

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)

# PLCopen XML namespace
NS = "http://www.plcopen.org/xml/tc6_0201"


def read_file(relpath):
    """Read a file relative to PROJECT_ROOT."""
    filepath = os.path.join(PROJECT_ROOT, relpath)
    with open(filepath, "r", encoding="utf-8") as f:
        return f.read()


def parse_st_pou(source, pou_type="functionBlock"):
    """Split a ST file into declaration (VAR blocks) and implementation body."""
    # For PROGRAM or FUNCTION_BLOCK, split at the first executable statement
    # after the last END_VAR
    lines = source.split("\n")

    # Find the header line (PROGRAM xxx or FUNCTION_BLOCK xxx)
    header_line = ""
    decl_lines = []
    impl_lines = []
    in_impl = False
    end_var_count = 0
    var_depth = 0

    for line in lines:
        stripped = line.strip().upper()

        if not in_impl:
            decl_lines.append(line)
            if stripped.startswith("VAR") and not stripped.startswith("VAR_"):
                var_depth += 1
            elif stripped.startswith("VAR_"):
                var_depth += 1
            if stripped == "END_VAR":
                var_depth -= 1
                if var_depth <= 0:
                    var_depth = 0
                    end_var_count += 1
            # Transition to implementation after last END_VAR and a non-empty non-VAR line
            if end_var_count > 0 and var_depth == 0 and stripped and not stripped.startswith("VAR") and not stripped == "END_VAR":
                # This line is actually implementation
                decl_lines.pop()
                impl_lines.append(line)
                in_impl = True
        else:
            impl_lines.append(line)

    decl_text = "\n".join(decl_lines)
    impl_text = "\n".join(impl_lines)

    # Remove trailing END_PROGRAM / END_FUNCTION_BLOCK from implementation
    impl_text = re.sub(r'\n\s*END_(PROGRAM|FUNCTION_BLOCK)\s*$', '', impl_text, flags=re.IGNORECASE)

    return decl_text.strip(), impl_text.strip()


def parse_st_dut(source):
    """Return the full DUT source as declaration."""
    return source.strip(), ""


def parse_st_gvl(source):
    """Return the full GVL source as declaration."""
    return source.strip(), ""


def build_plcopen_xml():
    """Build the PLCopen XML document."""
    # Root
    root = ET.Element("project", xmlns=NS)
    root.set("xmlns", NS)

    # File header
    fh = ET.SubElement(root, "fileHeader")
    fh.set("companyName", "")
    fh.set("productName", "IOWalkTest")
    fh.set("productVersion", "1.0")
    fh.set("creationDateTime", datetime.now().isoformat())

    # Content header
    ch = ET.SubElement(root, "contentHeader")
    ch.set("name", "IOWalkTest")
    ch.set("modificationDateTime", datetime.now().isoformat())
    coord = ET.SubElement(ch, "coordinateInfo")
    for axis in ["fbd", "ld", "sfc"]:
        info = ET.SubElement(coord, axis)
        s = ET.SubElement(info, "scaling")
        s.set("x", "1")
        s.set("y", "1")

    # Types
    types = ET.SubElement(root, "types")
    dataTypes = ET.SubElement(types, "dataTypes")
    pous = ET.SubElement(types, "pous")

    # DUTs
    dut_files = [
        "DUTs/E_TestState.st",
        "DUTs/E_TestResult.st",
        "DUTs/E_ContactType.st",
        "DUTs/E_AOPhase.st",
        "DUTs/ST_DIChannel.st",
        "DUTs/ST_DOChannel.st",
        "DUTs/ST_AIChannel.st",
        "DUTs/ST_AOChannel.st",
    ]
    for f in dut_files:
        source = read_file(f)
        name = os.path.splitext(os.path.basename(f))[0]
        dt = ET.SubElement(dataTypes, "dataType")
        dt.set("name", name)
        decl = ET.SubElement(dt, "baseType")
        # Store full source in a documentation element for manual import
        doc = ET.SubElement(dt, "documentation")
        xhtml = ET.SubElement(doc, "xhtml", xmlns="http://www.w3.org/1999/xhtml")
        xhtml.text = source

    # Function Blocks
    fb_files = [
        ("FBs/FB_DITest.st", "FB_DITest", "functionBlock"),
        ("FBs/FB_DOTest.st", "FB_DOTest", "functionBlock"),
        ("FBs/FB_AITest.st", "FB_AITest", "functionBlock"),
        ("FBs/FB_AOTest.st", "FB_AOTest", "functionBlock"),
    ]
    for filepath, name, pou_type in fb_files:
        source = read_file(filepath)
        decl_text, impl_text = parse_st_pou(source, pou_type)

        pou = ET.SubElement(pous, "pou")
        pou.set("name", name)
        pou.set("pouType", pou_type)

        interface = ET.SubElement(pou, "interface")
        # Store declaration as returnType documentation (CODESYS workaround)
        doc_decl = ET.SubElement(interface, "documentation")
        xhtml = ET.SubElement(doc_decl, "xhtml", xmlns="http://www.w3.org/1999/xhtml")
        xhtml.text = decl_text

        body = ET.SubElement(pou, "body")
        st = ET.SubElement(body, "ST")
        xhtml_impl = ET.SubElement(st, "xhtml", xmlns="http://www.w3.org/1999/xhtml")
        xhtml_impl.text = impl_text

    # Programs
    prg_files = [
        ("Programs/PRG_IOWalkTest.st", "PRG_IOWalkTest", "program"),
    ]
    for filepath, name, pou_type in prg_files:
        source = read_file(filepath)
        decl_text, impl_text = parse_st_pou(source, pou_type)

        pou = ET.SubElement(pous, "pou")
        pou.set("name", name)
        pou.set("pouType", pou_type)

        interface = ET.SubElement(pou, "interface")
        doc_decl = ET.SubElement(interface, "documentation")
        xhtml = ET.SubElement(doc_decl, "xhtml", xmlns="http://www.w3.org/1999/xhtml")
        xhtml.text = decl_text

        body = ET.SubElement(pou, "body")
        st = ET.SubElement(body, "ST")
        xhtml_impl = ET.SubElement(st, "xhtml", xmlns="http://www.w3.org/1999/xhtml")
        xhtml_impl.text = impl_text

    # Instances (GVLs stored as configurations)
    instances = ET.SubElement(root, "instances")
    configs = ET.SubElement(instances, "configurations")

    gvl_files = [
        "GVLs/GVL_HardwareIO.st",
        "GVLs/GVL_IOWalkTest.st",
    ]
    for f in gvl_files:
        source = read_file(f)
        name = os.path.splitext(os.path.basename(f))[0]
        config = ET.SubElement(configs, "configuration")
        config.set("name", name)
        doc = ET.SubElement(config, "documentation")
        xhtml = ET.SubElement(doc, "xhtml", xmlns="http://www.w3.org/1999/xhtml")
        xhtml.text = source

    return root


def main():
    parser = argparse.ArgumentParser(description="Export IOWalkTest to PLCopen XML")
    parser.add_argument("--output", "-o", default=None,
                        help="Output XML file path (default: <project>/IOWalkTest.xml)")
    args = parser.parse_args()

    output_path = args.output or os.path.join(PROJECT_ROOT, "IOWalkTest.xml")

    print("Generating PLCopen XML...")
    root = build_plcopen_xml()

    tree = ET.ElementTree(root)
    ET.indent(tree, space="  ")
    tree.write(output_path, encoding="utf-8", xml_declaration=True)

    print(f"Exported to: {output_path}")
    print(f"\nTo import into CODESYS v3.5:")
    print(f"  1. Open your project")
    print(f"  2. Project -> Import PLCopen XML...")
    print(f"  3. Select {output_path}")
    print(f"  4. Map IO variables in GVL_HardwareIO to your device IO mapping")
    print(f"\nNote: DUTs and GVLs may need to be created manually from the")
    print(f"      source files in DUTs/ and GVLs/ folders, as PLCopen XML")
    print(f"      has limited support for these object types.")
    print(f"      The raw .st source is embedded in documentation elements.")


if __name__ == "__main__":
    main()
