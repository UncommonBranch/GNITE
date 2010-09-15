Then /^I should see a node "([^"]*)" at the root level in my reference tree "([^"]*)"$/ do |node_text, reference_tree_title|
  reference_tree = ReferenceTree.find_by_title(reference_tree_title)
  page.should have_css("div##{dom_id(reference_tree, "container_for")}>ul>li>a:contains('#{node_text}')")
end

Then /^I should see an? "([^"]*)" tab$/ do |tab_name|
  page.should have_css("ul.ui-tabs-nav>li>a:contains('#{tab_name}')")
end

Then /^the "([^"]*)" tab should be active$/ do |tab_name|
  page.should have_css("ul.ui-tabs-nav>li.ui-state-active>a:contains('#{tab_name}')")
end


Then /^I should not be able to show a context menu for my reference tree "(.*)"$/ do |reference_tree_title|
  reference_tree = ReferenceTree.find_by_title(reference_tree_title)
  reference_tree_matcher = "div##{dom_id(reference_tree, "container_for")}"
  page.should have_css(reference_tree_matcher)

  page.execute_script("jQuery('#{reference_tree_matcher}').jstree('show_contextmenu');");
  sleep 1

  find_link('Create').should be_nil
  find_link('Rename').should be_nil
  find_link('Delete').should be_nil
end

When /^I drag "([^"]*)" under "([^"]*)" in my reference tree "(.*)"$/ do |origin_node_text, destination_node_text, reference_tree_title|
  reference_tree         = ReferenceTree.find_by_title(reference_tree_title)
  reference_tree_matcher = "div##{dom_id(reference_tree, "container_for")}"
  origin_node            = Node.joins(:name).where('names.name_string = ?', origin_node_text).first
  destination_node       = Node.joins(:name).where('names.name_string = ?', destination_node_text).first

  When %{I select the node "#{origin_node.name_string}"}
  page.execute_script("jQuery('#{reference_tree_matcher}').jstree('move_node', '##{origin_node.id}', '##{destination_node.id}', 'first', false);")
end
