// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

//= require jquery
//= require jquery_ujs

function clearText(field) {
  if (field.defaultValue == field.value) field.value = '';
  else if (field.value == '') field.value = field.defaultValue;
}
