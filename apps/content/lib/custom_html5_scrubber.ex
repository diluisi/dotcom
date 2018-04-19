defmodule Content.CustomHTML5Scrubber do
  @moduledoc """
  Created to be used in place of HtmlSanitizeEx.html5
  so we can add to the list of allowed attributes.

  Custom additions are:
  - Inclusion of 'mailto' in valid_schemes
  - Provides missing quotes to "alt crossorigin usemap ismap width height"
  """

  require HtmlSanitizeEx.Scrubber.Meta
  alias HtmlSanitizeEx.Scrubber.Meta

  # Removes any CDATA tags before the traverser/scrubber runs.
  Meta.remove_cdata_sections_before_scrub

  Meta.strip_comments

  @valid_schemes ["http", "https", "mailto", "tel"]

  Meta.allow_tag_with_uri_attributes   "a", ["href"], @valid_schemes
  Meta.allow_tag_with_these_attributes "a", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid",
    "itemprop", "itemref", "itemscope", "itemtype", "lang", "role",
    "spellcheck", "tabindex", "title", "translate",
    "target", "ping", "rel", "media", "hreflang", "type"]

  Meta.allow_tag_with_these_attributes "b", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "blockquote", [
    "accesskey", "cite", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "br", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "caption", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid",
    "itemprop", "itemref", "itemscope", "itemtype", "lang", "role",
    "spellcheck", "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "code", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "del", [
    "accesskey", "cite", "datetime", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "div", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "em", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "figure", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "figcaption", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "h1", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "h2", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "h3", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "h4", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "h5", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "h6", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "head", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "header", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "hgroup", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "hr", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "html", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate", "manifest"]

  Meta.allow_tag_with_these_attributes "i", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_uri_attributes   "iframe", ["src"], @valid_schemes
  Meta.allow_tag_with_these_attributes "iframe", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate",
    "name", "sandbox", "seamless", "width", "height"]

  Meta.allow_tag_with_uri_attributes   "img", ["src", "lowsrc", "srcset"], @valid_schemes
  Meta.allow_tag_with_these_attributes "img", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role",
    "spellcheck", "tabindex", "title", "translate",
    "alt", "crossorigin", "usemap", "ismap", "width", "height"]

  Meta.allow_tag_with_uri_attributes   "input", ["src"], @valid_schemes
  Meta.allow_tag_with_these_attributes "input", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate",
    "accept", "alt", "autocomplete", "autofocus", "checked", "dirname",
    "disabled", "form", "formaction", "formenctype", "formmethod", "formnovalidate",
    "formtarget", "height", "inputmode", "list", "max", "maxlength", "min", "multiple",
    "name", "pattern", "placeholder", "readonly", "required", "size", "step", "type", "value", "width"]

  Meta.allow_tag_with_these_attributes "ins", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate", "cite", "datetime"]

  Meta.allow_tag_with_these_attributes "kbd", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "keygen", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid",
    "itemprop", "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate", "autofocus", "challenge", "disabled", "form", "keytype", "name"]

  Meta.allow_tag_with_these_attributes "label", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate", "form", "for"]

  Meta.allow_tag_with_these_attributes "legend", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "li", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate", "value"]

  Meta.allow_tag_with_these_attributes "map", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate", "name"]

  Meta.allow_tag_with_these_attributes "mark", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "menu", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate", "type", "label"]

  Meta.allow_tag_with_these_attributes "meta", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate", "name", "http-equiv", "content", "charset"]

  Meta.allow_tag_with_these_attributes "meter", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate", "value", "min", "max", "low", "high", "optimum"]

  Meta.allow_tag_with_these_attributes "nav", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "object", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate",
    "data", "type", "typemustmatch", "name", "usemap", "form", "width", "height"]

  Meta.allow_tag_with_these_attributes "ol", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate", "reversed", "start"]

  Meta.allow_tag_with_these_attributes "optgroup", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate", "disabled", "label"]

  Meta.allow_tag_with_these_attributes "option", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate", "disabled", "label", "selected", "value"]

  Meta.allow_tag_with_these_attributes "output", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate", "for", "form", "name"]

  Meta.allow_tag_with_these_attributes "p", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "param", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate", "name", "value"]

  Meta.allow_tag_with_these_attributes "pre", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "progress", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate", "value", "max"]

  Meta.allow_tag_with_these_attributes "q", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate", "cite"]

  Meta.allow_tag_with_these_attributes "rp", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "rt", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "ruby", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "s", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "samp", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "section", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "select", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate", "autofocus", "disabled", "form",
    "multiple", "name", "required", "size"]

  Meta.allow_tag_with_these_attributes "small", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_uri_attributes   "source", ["src"], @valid_schemes
  Meta.allow_tag_with_these_attributes "source", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate", "type", "media"]

  Meta.allow_tag_with_these_attributes "span", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "strong", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "sub", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "summary", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "sup", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "table", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "tbody", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "td", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate", "colspan", "rowspan", "headers"]

  Meta.allow_tag_with_these_attributes "textarea", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate", "autocomplete", "autofocus", "cols",
    "dirname", "disabled", "form", "inputmode", "maxlength", "name",
    "placeholder", "readonly", "required", "rows", "wrap"]

  Meta.allow_tag_with_these_attributes "tfoot", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "th", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate", "colspan", "rowspan", "headers", "scope", "abbr"]

  Meta.allow_tag_with_these_attributes "thead", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "time", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate", "datetime", "pubdate"]

  Meta.allow_tag_with_these_attributes "title", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "tr", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_uri_attributes   "track", ["src"], @valid_schemes
  Meta.allow_tag_with_these_attributes "track", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate", "default", "kind", "label", "srclang"]

  Meta.allow_tag_with_these_attributes "u", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "ul", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_these_attributes "var", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tag_with_uri_attributes   "video", ["src"], @valid_schemes
  Meta.allow_tag_with_these_attributes "video", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate", "crossorigin", "poster", "preload",
    "autoplay", "mediagroup", "loop", "muted", "controls", "width", "height"]

  Meta.allow_tag_with_these_attributes "wbr", [
    "accesskey", "class", "contenteditable", "contextmenu", "dir",
    "draggable", "dropzone", "hidden", "id", "inert", "itemid", "itemprop",
    "itemref", "itemscope", "itemtype", "lang", "role", "spellcheck",
    "tabindex", "title", "translate"]

  Meta.allow_tags_with_style_attributes [
    "a", "blockquote", "br", "code", "del", "em", "h1", "h2", "h3", "h4", "h5", "h6",
    "head", "header", "hgroup", "hr", "html", "i", "iframe", "img", "input", "ins", "kbd", "keygen",
    "label", "legend", "li", "link", "map", "mark", "menu", "meta", "meter", "nav", "noscript", "object",
    "ol", "optgroup", "option", "output", "p", "param", "pre", "progress", "q", "rp", "rt", "ruby",
    "s", "samp", "script", "section", "select", "small", "source", "span", "strong", "sub", "summary",
    "sup", "table", "tbody", "td", "textarea", "tfoot", "th", "thead", "time", "title", "tr",
    "track", "u", "ul", "var", "video", "wbr"]

  Meta.strip_everything_not_covered

  @spec html5(String.t) :: String.t
  def html5(html) do
    html |> HtmlSanitizeEx.Scrubber.scrub(__MODULE__)
  end

  defp scrub_css(text) do
    HtmlSanitizeEx.Scrubber.CSS.scrub(text)
  end
end
