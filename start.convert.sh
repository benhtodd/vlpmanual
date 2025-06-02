#!/bin/bash

# Set script paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/convert_xml_to_docx.py"
VENV_DIR="$SCRIPT_DIR/.venv"

# Set paths for input/output
XML_FILE="content.xml"
DOCX_FILE="output_manual.docx"

# Create virtual environment if not already present
if [ ! -d "$VENV_DIR" ]; then
  echo "🔧 Creating virtual environment..."
  python3 -m venv "$VENV_DIR"
fi

# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Install dependencies
echo "📦 Installing required packages..."
pip install --quiet --upgrade pip
pip install --quiet python-docx beautifulsoup4 lxml

# Run the Python conversion script
echo "📄 Converting $XML_FILE to $DOCX_FILE..."
python "$PYTHON_SCRIPT"

# Deactivate environment
deactivate

echo "✅ Done. File created: $DOCX_FILE"

And here is the python script "convert_xml_to_docx.py"
import os
import xml.etree.ElementTree as ET
from docx import Document
from docx.shared import Inches
from html import unescape
from bs4 import BeautifulSoup

# Ask user for the folder path
base_folder = input("Enter the path to the folder containing 'content.xml' and the 'images' folder [default: current directory]: ").strip()
if not base_folder:
    base_folder = os.getcwd()
else:
    base_folder = os.path.abspath(base_folder)

# Define paths
XML_PATH = os.path.join(base_folder, "content.xml")
IMAGES_DIR = os.path.join(base_folder, "images")
DOCX_PATH = os.path.join(base_folder, "output_manual.docx")

# Validate content.xml existence
if not os.path.isfile(XML_PATH):
    print(f"❌ ERROR: 'content.xml' not found in {base_folder}")
    exit(1)

# Load XML
tree = ET.parse(XML_PATH)
root = tree.getroot()

# Init DOCX document
doc = Document()
doc.add_heading("Lab Manual", 0)

# Helper to convert HTML to DOCX
def add_html_content(html_content, doc):
    soup = BeautifulSoup(unescape(html_content), "html.parser")
    for elem in soup.children:
        if elem.name == 'p':
            doc.add_paragraph(elem.get_text())
        elif elem.name == 'ul':
            for li in elem.find_all('li'):
                doc.add_paragraph(li.get_text(), style='List Bullet')
        elif elem.name == 'ol':
            for li in elem.find_all('li'):
                doc.add_paragraph(li.get_text(), style='List Number')
        elif elem.name == 'img':
            src = elem.get('src')
            if src:
                filename = os.path.basename(src)
                image_path = os.path.join(IMAGES_DIR, filename)
                if os.path.isfile(image_path):
                    doc.add_picture(image_path, width=Inches(5))

# Recursively process ContentNodes
def process_node(node, doc):
    title = node.findtext('title')
    if title:
        doc.add_heading(title, level=2)

    localizations = node.find('localizations')
    if localizations is not None:
        for loc in localizations.findall('LocaleContent'):
            content = loc.findtext('content')
            if content:
                add_html_content(content, doc)

    children = node.find('children')
    if children is not None:
        for child in children.findall('ContentNode'):
            process_node(child, doc)

# Main content traversal
content_nodes = root.find('contentNodes')
if content_nodes is not None:
    for node in content_nodes.findall('ContentNode'):
        process_node(node, doc)

# Save the DOCX
doc.save(DOCX_PATH)
print(f"✅ DOCX file created at: {DOCX_PATH}")