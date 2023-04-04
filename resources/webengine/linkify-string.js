/*
* Copyright (c) 2021 SoapBox Innovations Inc.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/
var linkifyStr = (function (linkifyjs) {
	'use strict';

	/**
		Convert strings of text into linkable HTML text
	*/

	function escapeText(text) {
	  return text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
	}

	function escapeAttr(href) {
	  return href.replace(/"/g, '&quot;');
	}

	function attributesToString(attributes) {
	  var result = [];

	  for (var attr in attributes) {
	    var val = attributes[attr] + '';
	    result.push(attr + "=\"" + escapeAttr(val) + "\"");
	  }

	  return result.join(' ');
	}

	function defaultRender(_ref) {
	  var tagName = _ref.tagName,
	      attributes = _ref.attributes,
	      content = _ref.content;
	  return "<" + tagName + " " + attributesToString(attributes) + ">" + escapeText(content) + "</" + tagName + ">";
	}
	/**
	 * Convert a plan text string to an HTML string with links. Expects that the
	 * given strings does not contain any HTML entities. Use the linkify-html
	 * interface if you need to parse HTML entities.
	 *
	 * @param {string} str string to linkify
	 * @param {import('linkifyjs').Opts} [opts] overridable options
	 * @returns {string}
	 */


	function linkifyStr(str, opts) {
	  if (opts === void 0) {
	    opts = {};
	  }

	  opts = new linkifyjs.Options(opts, defaultRender);
	  var tokens = linkifyjs.tokenize(str);
	  var result = [];

	  for (var i = 0; i < tokens.length; i++) {
	    var token = tokens[i];

	    if (token.t === 'nl' && opts.get('nl2br')) {
	      result.push('<br>\n');
	    } else if (!token.isLink || !opts.check(token)) {
	      result.push(escapeText(token.toString()));
	    } else {
	      result.push(opts.render(token));
	    }
	  }

	  return result.join('');
	}

	if (!String.prototype.linkify) {
	  Object.defineProperty(String.prototype, 'linkify', {
	    writable: false,
	    value: function linkify(options) {
	      return linkifyStr(this, options);
	    }
	  });
	}

	return linkifyStr;

})(linkify);