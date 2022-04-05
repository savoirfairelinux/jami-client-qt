#!/usr/bin/env python3

with open('qml_without_webengine.qrc', 'w') as outfile:
  with open('qml.qrc', 'r') as infile:
    line = infile.readline()
    while line:
      if 'EmojiPicker.qml' in line:
        outfile.write('\t<file>src/nowebengine/EmojiPicker.qml</file>\n')
      elif 'MediaPreviewBase.qml' in line:
        outfile.write('\t<file>src/nowebengine/MediaPreviewBase.qml</file>\n')
      else:
        outfile.write(line)
      line = infile.readline()
