Then /^"([^"]*)" should link to email "([^"]*)"$/ do |locator, email|
  link = find_link(locator)
  link['href'].should == "mailto:#{email}"
end

Then /^I should be focused on the master tree title field$/ do
  page.evaluate_script("jQuery('#master_tree_title')[0] == document.activeElement").should be_true
end

When /^I click on the page$/ do
  page.execute_script("jQuery('a').focus();")
  page.execute_script("jQuery('#master_tree_title').blur();")
end

Then /^"([^"]*)" should be checked/ do |label|
  field = find_field(label)
  field['checked'].should == 'true'
end
