/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

// This file contains the functions that allow the user to format the text in
// the message bar by adding bold, italic, underline, strikethrough, ordered
// list, and unordered list styles.

function isStyle(ta, text, char1, char2) {
  const start = ta.selectionStart;
  const end = ta.selectionEnd;

  if (char1 === '**') {
    return isStarStyle(ta, text, 'bold');
  }
  if (char1 === '*') {
    return isStarStyle(ta, text, 'italic');
  }
  const selectedText = text.substring(start - char1.length, end + char2.length);
  return (selectedText.startsWith(char1) && selectedText.endsWith(char2));
}

function isStarStyle(ta, text, type) {
  const selectionStart = ta.selectionStart;
  const selectionEnd = ta.selectionEnd;

  let start = selectionStart;
  while (start > 0 && text[start - 1] === '*') {
    start--;
  }
  let end = selectionEnd;
  while (end < text.length && text[end] === '*') {
    end++;
  }
  const starCount = Math.min(selectionStart - start, end - selectionEnd);
  if (type === 'italic') {
    return starCount === 1 || starCount === 3;
  }
  return starCount === 2 || starCount === 3;
}

function addStyle(ta, text, char1, char2) {
  const start = ta.selectionStart;
  const end = ta.selectionEnd;

  // Get the selected text with markdown effect
  var selectedText = text.substring(start - char1.length, end + char2.length);

  // If the selected text is already formatted with the given characters, remove
  // them
  if (isStyle(ta, text, char1, char2)) {
    selectedText = text.substring(start, end);
    ta.text = text.substring(0, start - char1.length) + selectedText +
        text.substring(end + char2.length);
    ta.selectText(start - char1.length, end - char1.length);
    return;
  }

  // Otherwise, add the formatting characters to the selected text
  ta.text = text.substring(0, start) + char1 + text.substring(start, end) +
      char2 + text.substring(end);
  ta.selectText(start + char1.length, end + char1.length);
}

function isPrefixSyle(ta, message, delimiter, isOrderedList) {
  const selectionStart = ta.selectionStart;
  const selectionEnd = ta.selectionEnd;

  // Represents all the selected lines
  var multilineSelection;
  var newPrefix;
  var newSuffix;
  var newStartPos;
  var newEndPos;
  function nextIndexOf(text, char1, startPos) {
    return text.indexOf(char1, startPos + 1);
  }

  // Get the previous index of the multilineSelection text
  if (message[selectionStart] === '\n')
    newStartPos = message.lastIndexOf('\n', selectionStart - 1);
  else
    newStartPos = message.lastIndexOf('\n', selectionStart);

  // Get the next index of the multilineSelection text
  if (message[selectionEnd] === '\n' || message[selectionEnd] === undefined)
    newEndPos = selectionEnd;
  else
    newEndPos = nextIndexOf(message, '\n', selectionEnd);

  // If the text is empty
  if (newStartPos === -1) newStartPos = 0;
  newPrefix = message.slice(0, newStartPos);
  multilineSelection = message.slice(newStartPos, newEndPos);
  newSuffix = message.slice(newEndPos);
  var isFirstLineSelected =
      !multilineSelection.startsWith('\n') || newPrefix === '';
  var getDelimiter_counter = 1;
  function getDelimiter() {
    return `${getDelimiter_counter++}. `;
  }
  function getHasCurrentMarkdown() {
    const linesQuantity = (multilineSelection.match(/\n/g) || []).length;
    const newLinesWithDelimitersQuantity =
        (multilineSelection.match(new RegExp(`\n${delimiter}`, 'g')) ||
         []).length;
    if (newLinesWithDelimitersQuantity === linesQuantity &&
        !isFirstLineSelected)
      return true;
    return linesQuantity === newLinesWithDelimitersQuantity &&
        multilineSelection.startsWith(delimiter);
  }
  function getHasCurrentMarkdownBullet() {
    const linesQuantity = (multilineSelection.match(/\n/g) || []).length;
    const newLinesWithDelimitersQuantity =
        (multilineSelection.match(/\n\d+\. /g) || []).length;
    if (newLinesWithDelimitersQuantity === linesQuantity &&
        !isFirstLineSelected)
      return true;
    return linesQuantity === newLinesWithDelimitersQuantity &&
        (/^\d\. /).test(multilineSelection);
  }
  var newValue;
  var newStart;
  var newEnd;
  var count;
  var startPos;
  var multilineSelectionLength;
  if (!isOrderedList) {
    return getHasCurrentMarkdown();
  } else {
    return getHasCurrentMarkdownBullet();
  }
}

function addPrefixStyle(ta, message, delimiter, isOrderedList) {
  const selectionStart = ta.selectionStart;
  const selectionEnd = ta.selectionEnd;

  // Represents all the selected lines
  var multilineSelection;
  var newPrefix;
  var newSuffix;
  var newStartPos;
  var newEndPos;
  function nextIndexOf(text, char1, startPos) {
    return text.indexOf(char1, startPos + 1);
  }

  // Get the previous index of the multilineSelection text
  if (message[selectionStart] === '\n')
    newStartPos = message.lastIndexOf('\n', selectionStart - 1);
  else
    newStartPos = message.lastIndexOf('\n', selectionStart);

  // Get the next index of the multilineSelection text
  if (message[selectionEnd] === '\n' || message[selectionEnd] === undefined)
    newEndPos = selectionEnd;
  else
    newEndPos = nextIndexOf(message, '\n', selectionEnd);

  // If the text is empty
  if (newStartPos === -1) newStartPos = 0;
  newPrefix = message.slice(0, newStartPos);
  multilineSelection = message.slice(newStartPos, newEndPos);
  newSuffix = message.slice(newEndPos);
  var isFirstLineSelected =
      !multilineSelection.startsWith('\n') || newPrefix === '';
  var getDelimiter_counter = 1;
  function getDelimiter() {
    return `${getDelimiter_counter++}. `;
  }
  function getHasCurrentMarkdown() {
    const linesQuantity = (multilineSelection.match(/\n/g) || []).length;
    const newLinesWithDelimitersQuantity =
        (multilineSelection.match(new RegExp(`\n${delimiter}`, 'g')) ||
         []).length;
    if (newLinesWithDelimitersQuantity === linesQuantity &&
        !isFirstLineSelected)
      return true;
    return linesQuantity === newLinesWithDelimitersQuantity &&
        multilineSelection.startsWith(delimiter);
  }
  function getHasCurrentMarkdownBullet() {
    const linesQuantity = (multilineSelection.match(/\n/g) || []).length;
    const newLinesWithDelimitersQuantity =
        (multilineSelection.match(/\n\d+\. /g) || []).length;
    if (newLinesWithDelimitersQuantity === linesQuantity &&
        !isFirstLineSelected)
      return true;
    return linesQuantity === newLinesWithDelimitersQuantity &&
        (/^\d\. /).test(multilineSelection);
  }
  var newValue;
  var newStart;
  var newEnd;
  var count;
  var startPos;
  var multilineSelectionLength;
  if (!isOrderedList) {
    if (getHasCurrentMarkdown()) {
      // Clear first line from delimiter
      if (isFirstLineSelected)
        multilineSelection = multilineSelection.slice(delimiter.length);
      newValue = newPrefix +
          multilineSelection.replace(new RegExp(`\n${delimiter}`, 'g'), '\n') +
          newSuffix;
      count = 0;
      if (isFirstLineSelected) count++;
      count += (multilineSelection.match(/\n/g) || []).length;
      newStart = Math.max(selectionStart - delimiter.length, 0);
      newEnd = Math.max(selectionEnd - (delimiter.length * count), 0);
    } else {
      newValue = newPrefix +
          multilineSelection.replace(/\n/g, `\n${delimiter}`) + newSuffix;
      count = 0;
      if (isFirstLineSelected) {
        newValue = delimiter + newValue;
        count++;
      }
      count += (multilineSelection.match(new RegExp('\\n', 'g')) || []).length;
      newStart = selectionStart + delimiter.length;
      newEnd = selectionEnd + (delimiter.length * count);
    }
  } else if (getHasCurrentMarkdownBullet()) {
    if (message[selectionStart] === '\n')
      startPos = message.lastIndexOf('\n', selectionStart - 1) + 1;
    else
      startPos = message.lastIndexOf('\n', selectionStart) + 1;
    newStart = startPos;
    multilineSelection = multilineSelection.replace(/^\d+\.\s/gm, '');
    newValue = newPrefix + multilineSelection + newSuffix;
    multilineSelectionLength = multilineSelection.length;

    // If the first line is not selected, we need to remove the first "\n" of
    // multilineSelection
    if (newStart) multilineSelectionLength = multilineSelection.length - 1;
    newEnd = Math.max(newStart + multilineSelectionLength, 0);
  } else {
    if (message[selectionStart] === '\n')
      startPos = message.lastIndexOf('\n', selectionStart - 1) + 1;
    else
      startPos = message.lastIndexOf('\n', selectionStart) + 1;
    newStart = startPos;

    // If no text is selected
    if (selectionStart === selectionEnd) newStart = newStart + 3;
    if (isFirstLineSelected)
      multilineSelection = getDelimiter() + multilineSelection;
    const selectionArr = Array.from(multilineSelection);
    for (var i = 0; i < selectionArr.length; i++) {
      if (selectionArr[i] === '\n') selectionArr[i] = `\n${getDelimiter()}`;
    }
    multilineSelection = selectionArr.join('');
    newValue = newPrefix + multilineSelection + newSuffix;
    multilineSelectionLength = multilineSelection.length;

    // If the first line is not selected, we meed to remove the first "\n" of
    // multilineSelection
    if (startPos) multilineSelectionLength = multilineSelection.length - 1;
    newEnd = Math.max(startPos + multilineSelectionLength, 0);
  }

  ta.text = newValue;
  ta.selectText(newStart, newEnd);
}
